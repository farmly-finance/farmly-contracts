pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./library/FarmlyFullMath.sol";
import "./library/FarmlyStructs.sol";
import "./interfaces/IFarmlyVault.sol";
import "./interfaces/IFarmlyUniV3Executor.sol";

contract FarmlyPositionManager {
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

    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) public userPositions;
    uint256 public nextPositionID = 1;

    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function createPosition(
        IFarmlyUniV3Executor executor,
        uint amount0,
        uint amount1,
        VaultInfo memory vault0,
        VaultInfo memory vault1,
        FarmlyStructs.PositionInfo memory positionInfo,
        FarmlyStructs.SwapInfo memory swapInfo
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
        VaultInfo memory vault0,
        VaultInfo memory vault1,
        FarmlyStructs.PositionInfo memory positionInfo,
        FarmlyStructs.SwapInfo memory swapInfo
    ) public {
        Position storage position = positions[positionID];
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

        executor.increase(
            position.uniV3PositionID,
            msg.sender,
            amount0 + vault0.debtAmount,
            amount1 + vault1.debtAmount,
            positionInfo,
            swapInfo
        );

        position.debt0.debtShare += debtShare0;
        position.debt1.debtShare += debtShare1;
        position.debt0.vault.debtAmount += vault0.debtAmount;
        position.debt1.vault.debtAmount += vault1.debtAmount;
    }

    function collectFees(
        IFarmlyUniV3Executor executor,
        uint256 positionID
    )
        public
        returns (bytes memory _data, bytes memory _response, uint256, uint256)
    {
        Position storage position = positions[positionID];
        (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1
        ) = executor.collect(position.uniV3PositionID);
        IERC20(token0).transfer(msg.sender, amount0);
        IERC20(token1).transfer(msg.sender, amount1);
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
}
