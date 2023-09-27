pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./library/FarmlyFullMath.sol";
import "./library/FarmlyStructs.sol";
import "./library/FarmlyTransferHelper.sol";
import "./interfaces/IFarmlyVault.sol";
import "./interfaces/IFarmlyUniV3Executor.sol";
import "./interfaces/IFarmlyPriceConsumer.sol";
import "./interfaces/IFarmlyConfig.sol";
import "./interfaces/IFarmlyUniV3Reader.sol";

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

    struct CreatePositionParams {
        IFarmlyUniV3Executor executor;
        uint amount0;
        uint amount1;
        VaultInfo vault0;
        VaultInfo vault1;
        FarmlyStructs.PositionInfo positionInfo;
        FarmlyStructs.SwapInfo swapInfo;
        SlippageProtection slippage;
    }

    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) public userPositions;

    uint256 public nextPositionID;

    IFarmlyPriceConsumer public farmlyPriceConsumer =
        IFarmlyPriceConsumer(0xF28f90B3c87e075eC5749383DC055dba72835B15);

    IFarmlyConfig public farmlyConfig =
        IFarmlyConfig(0xBc017650E1B704a01e069fa4189fccbf5D767f9C);

    IFarmlyUniV3Reader public farmlyUniV3Reader =
        IFarmlyUniV3Reader(0x8727Ded114fE87E8aEC40E51D29989fD66ccE622);

    constructor() {
        nextPositionID++;
    }

    modifier updateDebtAmount(uint positionID) {
        Position storage position = positions[positionID];
        position.debt0.vault.debtAmount = position
            .debt0
            .vault
            .vault
            .debtShareToDebt(position.debt0.debtShare);
        position.debt1.vault.debtAmount = position
            .debt1
            .vault
            .vault
            .debtShareToDebt(position.debt1.debtShare);
        _;
    }

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
        if (amount0 > 0)
            FarmlyTransferHelper.safeTransferFrom(
                positionInfo.token0,
                msg.sender,
                address(this),
                amount0
            );

        if (amount1 > 0)
            FarmlyTransferHelper.safeTransferFrom(
                positionInfo.token1,
                msg.sender,
                address(this),
                amount1
            );

        uint debtShare0 = vault0.vault.borrow(vault0.debtAmount);
        uint debtShare1 = vault1.vault.borrow(vault1.debtAmount);

        FarmlyTransferHelper.safeApprove(
            positionInfo.token0,
            address(executor),
            amount0 + vault0.debtAmount
        );

        FarmlyTransferHelper.safeApprove(
            positionInfo.token1,
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

        (, , uint256 positionTotalUSDValue) = farmlyUniV3Reader
            .getPositionUSDValue(tokenId);

        require(
            positionTotalUSDValue > slippage.minPositionUSDValue,
            "SLIPPAGE: MIN_USD"
        );

        uint debtUSD = _calcDebtUSD(
            address(positionInfo.token0),
            vault0.debtAmount,
            address(positionInfo.token1),
            vault1.debtAmount
        );

        require(
            _calcLeverage(positionTotalUSDValue, debtUSD) <
                slippage.maxLeverageTolerance,
            "SLIPPAGE: MAX_LEVERAGE"
        );

        positions[nextPositionID] = Position(
            tokenId,
            msg.sender,
            DebtInfo(vault0, debtShare0),
            DebtInfo(vault1, debtShare1)
        );

        userPositions[msg.sender].push(nextPositionID);

        nextPositionID++;
    }

    function increasePosition(
        uint256 positionID,
        IFarmlyUniV3Executor executor,
        uint amount0,
        uint amount1,
        uint debtAmount0,
        uint debtAmount1,
        FarmlyStructs.SwapInfo memory swapInfo,
        SlippageProtection memory slippage
    ) public updateDebtAmount(positionID) {
        Position storage position = positions[positionID];

        executor.collect(position.uniV3PositionID, msg.sender);

        (address token0, address token1, , , , ) = farmlyUniV3Reader
            .getPositionInfo(position.uniV3PositionID);

        if (amount0 > 0)
            FarmlyTransferHelper.safeTransferFrom(
                token0,
                msg.sender,
                address(this),
                amount0
            );
        if (amount1 > 0)
            FarmlyTransferHelper.safeTransferFrom(
                token1,
                msg.sender,
                address(this),
                amount1
            );

        uint debtShare0 = position.debt0.vault.vault.borrow(debtAmount0);
        uint debtShare1 = position.debt1.vault.vault.borrow(debtAmount1);

        FarmlyTransferHelper.safeApprove(
            token0,
            address(executor),
            amount0 + debtAmount0
        );
        FarmlyTransferHelper.safeApprove(
            token1,
            address(executor),
            amount1 + debtAmount1
        );

        executor.increase(
            position.uniV3PositionID,
            msg.sender,
            amount0 + debtAmount0,
            amount1 + debtAmount1,
            swapInfo
        );

        (, , uint256 positionTotalUSDValue) = farmlyUniV3Reader
            .getPositionUSDValue(position.uniV3PositionID);

        require(
            positionTotalUSDValue > slippage.minPositionUSDValue,
            "SLIPPAGE: MIN_USD"
        );

        uint debtUSD = _calcDebtUSD(
            token0,
            position.debt0.vault.debtAmount + debtAmount0,
            token1,
            position.debt1.vault.debtAmount + debtAmount1
        );

        require(
            _calcLeverage(positionTotalUSDValue, debtUSD) <
                slippage.maxLeverageTolerance,
            "SLIPPAGE: MAX_LEVERAGE"
        );

        position.debt0.debtShare += debtShare0;
        position.debt1.debtShare += debtShare1;
        position.debt0.vault.debtAmount += debtAmount0;
        position.debt1.vault.debtAmount += debtAmount1;
    }

    function decreasePosition(
        IFarmlyUniV3Executor executor,
        uint positionID,
        uint24 decreasingPercent
    ) public updateDebtAmount(positionID) {
        Position storage position = positions[positionID];

        executor.collect(position.uniV3PositionID, msg.sender);

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

        FarmlyTransferHelper.safeApprove(
            token0,
            address(position.debt0.vault.vault),
            amount0
        );

        FarmlyTransferHelper.safeApprove(
            token1,
            address(position.debt1.vault.vault),
            amount1
        );

        position.debt0.vault.vault.close(
            (position.debt0.debtShare * decreasingPercent) / 1000000
        );
        position.debt1.vault.vault.close(
            (position.debt1.debtShare * decreasingPercent) / 1000000
        );

        FarmlyTransferHelper.safeTransfer(token0, msg.sender, amount0 - debt0);
        FarmlyTransferHelper.safeTransfer(token1, msg.sender, amount1 - debt1);

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
        executor.collect(position.uniV3PositionID, msg.sender);
    }

    function collectAndIncrease(
        IFarmlyUniV3Executor executor,
        uint256 positionID,
        uint256 debt0,
        uint256 debt1,
        FarmlyStructs.SwapInfo memory swapInfo,
        SlippageProtection memory slippage
    ) public updateDebtAmount(positionID) {
        Position storage position = positions[positionID];
        (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1
        ) = executor.collect(position.uniV3PositionID, address(this));

        uint debtShare0 = position.debt0.vault.vault.borrow(debt0);
        uint debtShare1 = position.debt1.vault.vault.borrow(debt1);

        FarmlyTransferHelper.safeApprove(
            token0,
            address(executor),
            amount0 + debt0
        );
        FarmlyTransferHelper.safeApprove(
            token1,
            address(executor),
            amount1 + debt1
        );

        executor.increase(
            position.uniV3PositionID,
            msg.sender,
            amount0 + debt0,
            amount1 + debt1,
            swapInfo
        );

        (, , uint256 positionTotalUSDValue) = farmlyUniV3Reader
            .getPositionUSDValue(position.uniV3PositionID);

        require(
            positionTotalUSDValue > slippage.minPositionUSDValue,
            "SLIPPAGE: MIN_USD"
        );

        uint debtUSD = _calcDebtUSD(
            token0,
            position.debt0.vault.debtAmount + debt0,
            token1,
            position.debt1.vault.debtAmount + debt1
        );

        require(
            _calcLeverage(positionTotalUSDValue, debtUSD) <
                slippage.maxLeverageTolerance,
            "SLIPPAGE: MAX_LEVERAGE"
        );

        position.debt0.debtShare += debtShare0;
        position.debt1.debtShare += debtShare1;
        position.debt0.vault.debtAmount += debt0;
        position.debt1.vault.debtAmount += debt1;
    }

    function closePosition(
        IFarmlyUniV3Executor executor,
        uint256 positionID
    ) public updateDebtAmount(positionID) {
        Position storage position = positions[positionID];

        executor.collect(position.uniV3PositionID, msg.sender);

        uint256 debt0 = position.debt0.vault.debtAmount;
        uint256 debt1 = position.debt1.vault.debtAmount;

        (
            uint256 amount0,
            uint256 amount1,
            ,
            address token0,
            address token1,

        ) = executor.close(position.uniV3PositionID, debt0, debt1);

        FarmlyTransferHelper.safeApprove(
            token0,
            address(position.debt0.vault.vault),
            amount0
        );

        FarmlyTransferHelper.safeApprove(
            token1,
            address(position.debt1.vault.vault),
            amount1
        );

        position.debt0.vault.vault.close(position.debt0.debtShare);
        position.debt1.vault.vault.close(position.debt1.debtShare);

        FarmlyTransferHelper.safeTransfer(token0, msg.sender, amount0 - debt0);
        FarmlyTransferHelper.safeTransfer(token1, msg.sender, amount1 - debt1);

        position.debt0.debtShare = 0;
        position.debt1.debtShare = 0;
        position.debt0.vault.debtAmount = 0;
        position.debt1.vault.debtAmount = 0;
    }

    function liquidatePosition(
        IFarmlyUniV3Executor executor,
        uint256 positionID
    ) public updateDebtAmount(positionID) {
        require(getFlyScore(positionID) >= 10000, "Can't liquidate");

        Position storage position = positions[positionID];

        executor.collect(position.uniV3PositionID, msg.sender);

        uint256 debt0 = position.debt0.vault.debtAmount;
        uint256 debt1 = position.debt1.vault.debtAmount;

        (
            uint256 amount0,
            uint256 amount1,
            ,
            address token0,
            address token1,

        ) = executor.close(position.uniV3PositionID, debt0, debt1);

        FarmlyTransferHelper.safeApprove(
            token0,
            address(position.debt0.vault.vault),
            amount0
        );

        FarmlyTransferHelper.safeApprove(
            token1,
            address(position.debt1.vault.vault),
            amount1
        );

        position.debt0.vault.vault.close(position.debt0.debtShare);
        position.debt1.vault.vault.close(position.debt1.debtShare);

        FarmlyTransferHelper.safeTransfer(token0, msg.sender, amount0 - debt0);
        FarmlyTransferHelper.safeTransfer(token1, msg.sender, amount1 - debt1);

        position.debt0.debtShare = 0;
        position.debt1.debtShare = 0;
        position.debt0.vault.debtAmount = 0;
        position.debt1.vault.debtAmount = 0;
    }

    function getPositionUSDValue(
        uint256 positionID
    )
        public
        view
        returns (uint256 token0USD, uint256 token1USD, uint256 totalUSD)
    {
        Position memory position = positions[positionID];
        (token0USD, token1USD, totalUSD) = farmlyUniV3Reader
            .getPositionUSDValue(position.uniV3PositionID);
    }

    function getDebtRatio(
        uint256 positionID
    ) public view returns (uint256 debtRatio) {
        (, , uint256 debtUSD) = getDebtUSDValue(positionID);
        (, , uint256 totalUSD) = getPositionUSDValue(positionID);

        debtRatio = FarmlyFullMath.mulDiv(debtUSD, 1e6, totalUSD);
    }

    function getFlyScore(
        uint256 positionID
    ) public view returns (uint256 flyScrore) {
        uint256 debtRatio = getDebtRatio(positionID);
        flyScrore = FarmlyFullMath.mulDiv(
            debtRatio,
            10000,
            farmlyConfig.liquidationThreshold()
        );
    }

    function getDebtUSDValue(
        uint256 positionID
    )
        public
        view
        returns (uint256 debt0USD, uint256 debt1USD, uint256 debtUSD)
    {
        Position memory position = positions[positionID];
        (address token0, address token1, , , , ) = farmlyUniV3Reader
            .getPositionInfo(position.uniV3PositionID);
        uint debt0 = position.debt0.vault.vault.debtShareToDebt(
            position.debt0.debtShare
        );
        uint debt1 = position.debt1.vault.vault.debtShareToDebt(
            position.debt1.debtShare
        );
        debt0USD = farmlyPriceConsumer.calcUSDValue(token0, debt0);
        debt1USD = farmlyPriceConsumer.calcUSDValue(token1, debt1);
        debtUSD = debt0USD + debt1USD;
    }

    function getCurrentLeverage(
        uint256 positionID
    ) public view returns (uint256 leverage) {
        (, , uint256 totalUSD) = getPositionUSDValue(positionID);
        (, , uint256 debtUSD) = getDebtUSDValue(positionID);

        leverage = _calcLeverage(totalUSD, debtUSD);
    }

    function getDebtRatios(
        uint256 positionID
    ) public view returns (uint256 debtRatio0, uint256 debtRatio1) {
        (uint256 debt0, uint256 debt1, uint256 debtUSD) = getDebtUSDValue(
            positionID
        );

        debtRatio0 = FarmlyFullMath.mulDiv(debt0, 1000000, debtUSD);
        debtRatio1 = FarmlyFullMath.mulDiv(debt1, 1000000, debtUSD);
    }

    function getUserPositions(
        address user
    ) public view returns (uint256[] memory) {
        return userPositions[user];
    }

    function _calcLeverage(
        uint256 totalUSD,
        uint256 debtUSD
    ) internal pure returns (uint256 leverage) {
        leverage = FarmlyFullMath.mulDiv(totalUSD, 1000000, totalUSD - debtUSD);
    }

    function _calcDebtUSD(
        address token0,
        uint debt0,
        address token1,
        uint debt1
    ) internal view returns (uint debtUSD) {
        debtUSD =
            farmlyPriceConsumer.calcUSDValue(token0, debt0) +
            farmlyPriceConsumer.calcUSDValue(token1, debt1);
    }
}
