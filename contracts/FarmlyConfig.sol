pragma solidity >=0.5.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract FarmlyConfig is Ownable {
    mapping(address => mapping(address => address)) public poolVault;
    mapping(address => bool) public executers;

    function setFarmingPoolVault(
        address tokenA,
        address tokenB,
        address vault
    ) public onlyOwner {
        poolVault[tokenA][tokenB] = vault;
        poolVault[tokenB][tokenA] = vault;
    }

    function setExecuter(address _executer, bool _isActive) public onlyOwner {
        executers[_executer] = _isActive;
    }

    function getFarmingPoolVault(
        address tokenA,
        address tokenB
    ) public view returns (address) {
        return poolVault[tokenA][tokenB];
    }

    function getExecuter(address _executer) public view returns (bool) {
        return executers[_executer];
    }
}
