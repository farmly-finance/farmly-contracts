pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./library/FarmlyFullMath.sol";
import "./library/FarmlyStructs.sol";
import "./interfaces/IFarmlyVault.sol";
import "./interfaces/IFarmlyUniV3Executor.sol";
import "./interfaces/IFarmlyPriceConsumer.sol";
import "./interfaces/IFarmlyConfig.sol";

contract FarmlyPositionManager {
    struct SlippageProtection {
        uint256 minPositionUSDValue;
        uint256 maxLeverageTolerance; // 1000000 = 1x
    }

    struct VaultInfo {
        IFarmlyVault vault;
        uint debtAmount;
    }

    struct DebtInfo {
        VaultInfo vault;
        uint debtShare;
    }

    struct Position {
        uint uniV3PositionID;
        address owner;
        DebtInfo debt0;
        DebtInfo debt1;
    }

    IFarmlyPriceConsumer public farmlyPriceConsumer =
        IFarmlyPriceConsumer(0x101E0DaB98F20Ed2cadb98df804811Cb7B57Cf71);
    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) public userPositions;
    uint256 public nextPositionID;

    constructor() {
        nextPositionID++;
    }

    IFarmlyConfig public farmlyConfig =
        IFarmlyConfig(0x2b30e7B5a89c3D0225Fb1D07B4dc030BF1aa03a7);

    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function createPosition(
        IFarmlyUniV3Executor executor,
        uint amount0,
        uint amount1,
        VaultInfo memory vault0,
        VaultInfo memory vault1,
        FarmlyStructs.PositionInfo memory positionInfo,
        FarmlyStructs.SwapInfo memory swapInfo,
        SlippageProtection memory slippage
    ) public {
        positionInfo.token0.transferFrom(msg.sender, address(this), amount0);
        positionInfo.token1.transferFrom(msg.sender, address(this), amount1);
        uint debtShare0 = vault0.vault.borrow(vault0.debtAmount);
        uint debtShare1 = vault1.vault.borrow(vault1.debtAmount);
        positionInfo.token0.approve(
            address(executor),
            amount0 + vault0.debtAmount
        );
        positionInfo.token1.approve(
            address(executor),
            amount1 + vault1.debtAmount
        );

        uint256 tokenId = executor.execute(
            msg.sender,
            amount0 + vault0.debtAmount,
            amount1 + vault1.debtAmount,
            positionInfo,
            swapInfo
        );

        (
            uint256 positionTotalUSDValue,
            ,

        ) = _getPositionUSDValueWithUniV3PositionID(executor, tokenId);

        if (positionTotalUSDValue < slippage.minPositionUSDValue) revert();

        uint debtUSD = _tokenUSDValue(
            address(positionInfo.token0),
            vault0.debtAmount
        ) + _tokenUSDValue(address(positionInfo.token1), vault1.debtAmount);

        if (
            FarmlyFullMath.mulDiv(
                positionTotalUSDValue,
                1000000,
                positionTotalUSDValue - debtUSD
            ) > slippage.maxLeverageTolerance
        ) revert();

        positions[nextPositionID] = Position(
            tokenId,
            msg.sender,
            DebtInfo(vault0, debtShare0),
            DebtInfo(vault1, debtShare1)
        );

        userPositions[msg.sender].push(nextPositionID);

        nextPositionID++;
    }

    /* 
    Increasing Position with Protecting Leverage

    Params:
    Increase Rate // How much x? 1x = 1000000
    amoun0 
    amount1
    swapInfo

    */
    function increasePosition(
        uint256 positionID,
        IFarmlyUniV3Executor executor,
        uint increasingRate,
        uint amount0,
        uint amount1,
        IERC20 token0,
        IERC20 token1,
        FarmlyStructs.SwapInfo memory swapInfo
    ) public {
        Position storage position = positions[positionID];
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);
        uint debtAmount0 = FarmlyFullMath.mulDiv(
            position.debt0.vault.vault.debtShareToDebt(
                position.debt0.debtShare
            ),
            increasingRate,
            1000000
        );
        uint debtAmount1 = FarmlyFullMath.mulDiv(
            position.debt1.vault.vault.debtShareToDebt(
                position.debt1.debtShare
            ),
            increasingRate,
            1000000
        );
        uint debtShare0 = position.debt0.vault.vault.borrow(debtAmount0);
        uint debtShare1 = position.debt1.vault.vault.borrow(debtAmount1);

        token0.approve(address(executor), amount0 + debtAmount0);
        token1.approve(address(executor), amount1 + debtAmount1);

        executor.increase(
            position.uniV3PositionID,
            msg.sender,
            amount0 + debtAmount0,
            amount1 + debtAmount1,
            swapInfo
        );

        position.debt0.debtShare += debtShare0;
        position.debt1.debtShare += debtShare1;
        position.debt0.vault.debtAmount += debtAmount0;
        position.debt1.vault.debtAmount += debtAmount1;
    }

    /* 
    %100 = 1000000
    */

    function decreasePosition(
        IFarmlyUniV3Executor executor,
        uint positionID,
        uint24 decreasingPercent
    ) public {
        Position storage position = positions[positionID];

        uint256 debt0 = position.debt0.vault.vault.debtShareToDebt(
            (position.debt0.debtShare * decreasingPercent) / 1000000
        );
        uint256 debt1 = position.debt1.vault.vault.debtShareToDebt(
            (position.debt1.debtShare * decreasingPercent) / 1000000
        );

        (
            uint256 amount0,
            uint256 amount1,
            ,
            address token0,
            address token1,

        ) = executor.decrease(
                position.uniV3PositionID,
                decreasingPercent,
                debt0,
                debt1
            );

        IERC20(token0).approve(address(position.debt0.vault.vault), amount0);
        IERC20(token1).approve(address(position.debt1.vault.vault), amount1);

        position.debt0.vault.vault.close(
            (position.debt0.debtShare * decreasingPercent) / 1000000
        );
        position.debt1.vault.vault.close(
            (position.debt1.debtShare * decreasingPercent) / 1000000
        );

        IERC20(token0).transfer(msg.sender, amount0 - debt0);
        IERC20(token1).transfer(msg.sender, amount1 - debt1);

        position.debt0.debtShare -=
            (position.debt0.debtShare * decreasingPercent) /
            1000000;
        position.debt1.debtShare -=
            (position.debt1.debtShare * decreasingPercent) /
            1000000;
        position.debt0.vault.debtAmount -= debt0;
        position.debt1.vault.debtAmount -= debt1;
    }

    function collectFees(
        IFarmlyUniV3Executor executor,
        uint256 positionID
    ) public {
        Position storage position = positions[positionID];
        (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1
        ) = executor.collect(position.uniV3PositionID);

        uint256 amount0Fee = (amount0 * farmlyConfig.uniPerformanceFee()) /
            1000000;

        uint256 amount1Fee = (amount1 * farmlyConfig.uniPerformanceFee()) /
            1000000;

        IERC20(token0).transfer(farmlyConfig.feeAddress(), amount0Fee);
        IERC20(token1).transfer(farmlyConfig.feeAddress(), amount1Fee);

        IERC20(token0).transfer(msg.sender, amount0 - amount0Fee);
        IERC20(token1).transfer(msg.sender, amount1 - amount1Fee);
    }

    function collectAndIncrease(
        IFarmlyUniV3Executor executor,
        uint256 positionID,
        FarmlyStructs.SwapInfo memory swapInfo
    ) public {
        Position storage position = positions[positionID];
        (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1
        ) = executor.collect(position.uniV3PositionID);

        uint debt0 = FarmlyFullMath.mulDiv(
            amount0,
            getCurrentLeverage(executor, positionID) - 1000000,
            1000000
        );

        uint debt1 = FarmlyFullMath.mulDiv(
            amount1,
            getCurrentLeverage(executor, positionID) - 1000000,
            1000000
        );

        uint debtShare0 = position.debt0.vault.vault.borrow(debt0);
        uint debtShare1 = position.debt1.vault.vault.borrow(debt1);
        IERC20(token0).approve(address(executor), amount0 + debt0);
        IERC20(token1).approve(address(executor), amount1 + debt1);

        executor.increase(
            position.uniV3PositionID,
            msg.sender,
            amount0 + debt0,
            amount1 + debt1,
            swapInfo
        );

        position.debt0.debtShare += debtShare0;
        position.debt1.debtShare += debtShare1;
        position.debt0.vault.debtAmount += debt0;
        position.debt1.vault.debtAmount += debt1;
    }

    function closePosition(
        IFarmlyUniV3Executor executor,
        uint256 positionID
    ) public {
        Position storage position = positions[positionID];

        uint256 debt0 = position.debt0.vault.vault.debtShareToDebt(
            position.debt0.debtShare
        );
        uint256 debt1 = position.debt1.vault.vault.debtShareToDebt(
            position.debt1.debtShare
        );

        (
            uint256 amount0,
            uint256 amount1,
            ,
            address token0,
            address token1,

        ) = executor.close(position.uniV3PositionID, debt0, debt1);

        IERC20(token0).approve(address(position.debt0.vault.vault), amount0);
        IERC20(token1).approve(address(position.debt1.vault.vault), amount1);

        position.debt0.vault.vault.close(position.debt0.debtShare);
        position.debt1.vault.vault.close(position.debt1.debtShare);

        IERC20(token0).transfer(msg.sender, amount0 - debt0);
        IERC20(token1).transfer(msg.sender, amount1 - debt1);

        position.debt0.debtShare = 0;
        position.debt1.debtShare = 0;
        position.debt0.vault.debtAmount = 0;
        position.debt1.vault.debtAmount = 0;
    }

    function liquidatePosition(
        IFarmlyUniV3Executor executor,
        uint256 positionID
    ) public {
        Position storage position = positions[positionID];

        uint256 debt0 = position.debt0.vault.vault.debtShareToDebt(
            position.debt0.debtShare
        );
        uint256 debt1 = position.debt1.vault.vault.debtShareToDebt(
            position.debt1.debtShare
        );

        (
            uint256 amount0,
            uint256 amount1,
            ,
            address token0,
            address token1,

        ) = executor.close(position.uniV3PositionID, debt0, debt1);

        IERC20(token0).approve(address(position.debt0.vault.vault), amount0);
        IERC20(token1).approve(address(position.debt1.vault.vault), amount1);

        position.debt0.vault.vault.close(position.debt0.debtShare);
        position.debt1.vault.vault.close(position.debt1.debtShare);

        IERC20(token0).transfer(msg.sender, amount0 - debt0);
        IERC20(token1).transfer(msg.sender, amount1 - debt1);

        position.debt0.debtShare = 0;
        position.debt1.debtShare = 0;
        position.debt0.vault.debtAmount = 0;
        position.debt1.vault.debtAmount = 0;
    }

    function getPositionUSDValue(
        IFarmlyUniV3Executor executor,
        uint256 positionID
    )
        public
        view
        returns (uint256 token0USD, uint256 token1USD, uint256 totalUSD)
    {
        Position memory position = positions[positionID];
        (
            token0USD,
            token1USD,
            totalUSD
        ) = _getPositionUSDValueWithUniV3PositionID(
            executor,
            position.uniV3PositionID
        );
    }

    function getDebtUSDValue(
        IFarmlyUniV3Executor executor,
        uint256 positionID
    )
        public
        view
        returns (uint256 debt0USD, uint256 debt1USD, uint256 debtUSD)
    {
        Position memory position = positions[positionID];
        (address token0, address token1, , , , ) = executor.getPositionData(
            position.uniV3PositionID
        );
        uint debt0 = position.debt0.vault.vault.debtShareToDebt(
            position.debt0.debtShare
        );
        uint debt1 = position.debt1.vault.vault.debtShareToDebt(
            position.debt1.debtShare
        );
        debt0USD = _tokenUSDValue(token0, debt0);
        debt1USD = _tokenUSDValue(token1, debt1);
        debtUSD = debt0USD + debt1USD;
    }

    function getCurrentLeverage(
        IFarmlyUniV3Executor executor,
        uint256 positionID
    ) public view returns (uint256 leverage) {
        (, , uint256 totalUSD) = getPositionUSDValue(executor, positionID);
        (, , uint256 debtUSD) = getDebtUSDValue(executor, positionID);

        leverage = FarmlyFullMath.mulDiv(
            totalUSD, // 500
            1000000, // 100
            totalUSD - debtUSD
        );
    }

    function _getPositionUSDValueWithUniV3PositionID(
        IFarmlyUniV3Executor executor,
        uint256 uniV3PositionID
    )
        internal
        view
        returns (uint256 token0USD, uint256 token1USD, uint256 totalUSD)
    {
        (address token0, address token1, , , , ) = executor.getPositionData(
            uniV3PositionID
        );
        (uint256 amount0, uint256 amount1) = executor.getPositionAmounts(
            uniV3PositionID
        );

        token0USD = _tokenUSDValue(token0, amount0);
        token1USD = _tokenUSDValue(token1, amount1);
        totalUSD = token0USD + token1USD;
    }

    function _tokenUSDValue(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 price = farmlyPriceConsumer.getPrice(token);
        return FarmlyFullMath.mulDiv(price, amount, 1e18);
    }

    function getUserPositions(
        address user
    ) public view returns (uint256[] memory) {
        return userPositions[user];
    }
}

/*
    function multicall(
        bytes[] calldata data
    ) public returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
*/
