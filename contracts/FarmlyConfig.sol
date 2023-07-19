pragma solidity >=0.5.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract FarmlyConfig is Ownable {
    mapping(address => mapping(address => address)) public poolVault;
    mapping(address => bool) public executors;
    uint24 public uniPerformanceFee = 100000; // 100 = 1000000
    uint24 public vaultPerformanceFee = 200000;
    uint24 public liquidationPerformanceFee = 100000;
    address public feeAddress = 0xd59B898811F88C59E4673789a19Df51347d5Fa4f;

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
