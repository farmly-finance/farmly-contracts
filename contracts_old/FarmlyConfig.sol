pragma solidity >=0.5.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFarmlyInterestModel.sol";

contract FarmlyConfig is Ownable {
    /*
    mapping(address => mapping(address => address)) public poolVault;
    mapping(address => bool) public executors;
    */

    mapping(address => IFarmlyInterestModel) private vaultInterestModel;
    uint24 public uniPerformanceFee = 100000; // 100 = 1000000
    uint24 public vaultPerformanceFee = 200000;
    uint24 public liquidationPerformanceFee = 100000;
    uint24 public liquidationThreshold = 875000;
    address public feeAddress = 0x626c414DBE7c333eCd5b5C5F3B8E725c99C6f848;

    function getVaultInterestModel(
        address vault
    ) public view returns (IFarmlyInterestModel) {
        return vaultInterestModel[vault];
    }

    function setVaultInterestModel(
        address vault,
        IFarmlyInterestModel interestModel
    ) public onlyOwner {
        vaultInterestModel[vault] = interestModel;
    }
    /*
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
    */
}
