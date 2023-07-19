pragma solidity >=0.5.0;

interface IFarmlyConfig {
    function getFarmingPoolVault(
        address tokenA,
        address tokenB
    ) external view returns (address);

    function getExecutor(address _executor) external view returns (bool);

    function uniPerformanceFee() external view returns (uint24);

    function vaultPerformanceFee() external view returns (uint24);

    function liquidationPerformanceFee() external view returns (uint24);

    function feeAddress() external view returns (address);
}
