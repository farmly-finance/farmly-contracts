pragma solidity >=0.5.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract FarmlyConfig is Ownable {
    mapping(address => mapping(address => address)) public poolVault;
    mapping(address => bool) public executors;
    uint24 public uniPerformanceFee = 100000; // 100 = 1000000
    uint24 public vaultPerformanceFee = 200000;
    uint24 public liquidationPerformanceFee = 100000;
    uint24 public liquidationThreshold = 875000;
    address public feeAddress = 0x626c414DBE7c333eCd5b5C5F3B8E725c99C6f848;

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
