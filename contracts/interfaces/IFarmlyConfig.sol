pragma solidity >=0.5.0;

interface IFarmlyConfig {
    function getFarmingPoolVault(
        address tokenA,
        address tokenB
    ) external view returns (address);

    function getExecuter(address _executer) external view returns (bool);
}
