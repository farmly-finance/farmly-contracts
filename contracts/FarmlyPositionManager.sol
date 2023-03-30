pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFarmlyVault.sol";
import "./interfaces/IFarmlyConfig.sol";

contract FarmlyPositionManager {
    struct Position {
        address vault;
        address executer;
        address owner;
        uint256 debtShare;
    }

    mapping(uint256 => Position) public positions;
    uint256 public nextPositionID = 1;
    IFarmlyConfig public farmlyConfig;

    constructor(address _farmlyConfig) {
        farmlyConfig = IFarmlyConfig(_farmlyConfig);
    }

    function createPosition(
        IERC20 token,
        IERC20 debtToken,
        uint256 tokenAmount,
        uint256 debtTokenAmount,
        uint256 debtAmount,
        address executer
    ) public {
        require(farmlyConfig.getExecuter(executer), "INVALID EXECUTER");
        Position storage position = positions[nextPositionID];
        IFarmlyVault vault = getFarmingPoolVault(
            address(token),
            address(debtToken)
        );
        if (tokenAmount > 0) {
            token.transferFrom(msg.sender, address(this), tokenAmount);
        }
        if (debtTokenAmount > 0) {
            debtToken.transferFrom(msg.sender, address(this), debtTokenAmount);
        }

        position.vault = address(vault);
        position.executer = executer;
        position.owner = msg.sender;
        position.debtShare = vault.borrow(debtAmount);
        // to do: execute
    }

    function getFarmingPoolVault(
        address tokenA,
        address tokenB
    ) internal view returns (IFarmlyVault) {
        return IFarmlyVault(farmlyConfig.getFarmingPoolVault(tokenA, tokenB));
    }
}
