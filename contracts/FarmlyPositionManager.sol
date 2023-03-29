pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FarmlyPositionManager {
    struct Position {
        address executer;
        address owner;
        uint256 debtShare;
    }
}
