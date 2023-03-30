pragma solidity >=0.5.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract FarmlyConfig is Ownable {
    mapping(address => mapping(address => address)) public poolVault;
    mapping(address => bool) public executors;

    function setFarmingPoolVault(
        address tokenA,
        address tokenB,
        address vault
    ) public onlyOwner {
        poolVault[tokenA][tokenB] = vault;
        poolVault[tokenB][tokenA] = vault;
    }

    function setExecutor(address _executor, bool _isActive) public onlyOwner {
        executors[_executor] = _isActive;
    }

    function getFarmingPoolVault(
        address tokenA,
        address tokenB
    ) public view returns (address) {
        return poolVault[tokenA][tokenB];
    }

    function getExecutor(address _executor) public view returns (bool) {
        return executors[_executor];
    }
}
