pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./library/FarmlyFullMath.sol";
import "./interfaces/IFarmlyVault.sol";
import "./interfaces/IFarmlyConfig.sol";
import "./interfaces/IFarmlyDexExecutor.sol";

contract FarmlyPositionManager {
    struct Position {
        address vault;
        address executor;
        address owner;
        uint256 debtShare;
        uint256 lpAmount;
        address lpAddress;
        IERC20 vaultToken;
        IERC20 debtToken;
    }

    mapping(uint256 => Position) public positions;
    uint256 public nextPositionID = 1;
    IFarmlyConfig public farmlyConfig;
    uint256 public totalLpAmount;
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    constructor(address _farmlyConfig) {
        farmlyConfig = IFarmlyConfig(_farmlyConfig);
    }

    function createPosition(
        IERC20 token,
        IERC20 debtToken,
        uint256 tokenAmount,
        uint256 debtTokenAmount,
        uint256 debtAmount,
        address executor
    ) public {
        require(farmlyConfig.getExecutor(executor), "INVALID EXECUTOR");
        Position storage position = positions[nextPositionID];
        _createPosition(
            position,
            token,
            debtToken,
            tokenAmount,
            debtTokenAmount,
            debtAmount,
            executor,
            true
        );
        nextPositionID++;
    }

    function addCollectral(
        uint256 positionID,
        uint256 tokenAmount,
        uint256 debtTokenAmount,
        uint256 debtAmount,
        address executor
    ) public {
        require(farmlyConfig.getExecutor(executor), "INVALID EXECUTOR");
        Position storage position = positions[nextPositionID];
        _createPosition(
            position,
            position.vaultToken,
            position.debtToken,
            tokenAmount,
            debtTokenAmount,
            debtAmount,
            executor,
            false
        );
    }

    function closePosition(uint positionID) public {
        Position storage position = positions[positionID];
        _closePosition(position, position.lpAmount);
    }

    function partiallyClosePosition(uint positionID, uint lpAmount) public {
        Position storage position = positions[positionID];
        _closePosition(position, lpAmount);
    }

    function getPositionInfo(
        uint positionId
    )
        public
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            address,
            IERC20,
            IERC20
        )
    {
        Position memory position = positions[positionId];
        return (
            position.vault,
            position.executor,
            position.owner,
            position.debtShare,
            position.lpAmount,
            position.lpAddress,
            position.vaultToken,
            position.debtToken
        );
    }

    function _getFarmingPoolVault(
        address tokenA,
        address tokenB
    ) internal view returns (IFarmlyVault) {
        return IFarmlyVault(farmlyConfig.getFarmingPoolVault(tokenA, tokenB));
    }

    function _getDebtAmount(
        IFarmlyVault vault,
        uint debtShare
    ) internal view returns (uint) {
        uint totalDebt = vault.totalDebt();
        uint totalDebtShare = vault.totalDebtShare();
        uint pendingInterest = vault.pendingInterest(0);
        totalDebt += pendingInterest;
        return FarmlyFullMath.mulDiv(debtShare, totalDebt, totalDebtShare);
    }

    function _closePosition(Position storage position, uint lpAmount) internal {
        IERC20(position.lpAddress).transfer(position.executor, lpAmount);

        (
            address token0,
            address token1,
            uint amount0,
            uint amount1
        ) = IFarmlyDexExecutor(position.executor).close(
                address(position.debtToken),
                position.lpAddress,
                _getDebtAmount(IFarmlyVault(position.vault), position.debtShare)
            );
        IERC20(token1).approve(position.vault, MAX_INT);
        uint paidDebt = IFarmlyVault(position.vault).close(position.debtShare);
        amount1 -= paidDebt;
        position.debtShare = 0;
        position.lpAmount -= lpAmount;
        IERC20(token0).transfer(msg.sender, amount0);
        IERC20(token1).transfer(msg.sender, amount1);
        IERC20(token1).approve(position.vault, 0);
    }

    function _createPosition(
        Position storage position,
        IERC20 token,
        IERC20 debtToken,
        uint256 tokenAmount,
        uint256 debtTokenAmount,
        uint256 debtAmount,
        address executor,
        bool isNew
    ) internal {
        IFarmlyVault vault = _getFarmingPoolVault(
            address(token),
            address(debtToken)
        );
        if (tokenAmount > 0) {
            token.transferFrom(msg.sender, address(this), tokenAmount);
        }
        if (debtTokenAmount > 0) {
            debtToken.transferFrom(msg.sender, address(this), debtTokenAmount);
        }

        position.debtShare += vault.borrow(debtAmount);
        token.approve(executor, token.balanceOf(address(this)));
        debtToken.approve(executor, debtToken.balanceOf(address(this)));

        (uint lpAmount, address lpAddress) = IFarmlyDexExecutor(executor)
            .execute(
                token,
                debtToken,
                token.balanceOf(address(this)),
                debtToken.balanceOf(address(this))
            );

        if (isNew) {
            position.vault = address(vault);
            position.executor = executor;
            position.owner = msg.sender;
            position.lpAddress = lpAddress;
            position.vaultToken = token;
            position.debtToken = debtToken;
        }

        position.lpAmount += lpAmount;
        totalLpAmount += lpAmount;

        if (token.balanceOf(address(this)) > 0)
            token.transfer(msg.sender, token.balanceOf(address(this)));
        if (debtToken.balanceOf(address(this)) > 0)
            debtToken.transfer(msg.sender, debtToken.balanceOf(address(this)));
    }
}
