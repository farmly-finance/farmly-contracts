pragma solidity >=0.5.0;
import "./IFarmlyInterestModel.sol";

interface IFarmlyConfig {
    /*
    function getFarmingPoolVault(
        address tokenA,
        address tokenB
    ) external view returns (address);

    function getExecutor(address _executor) external view returns (bool);
    */

    function setVaultInterestModel(
        address vault,
        IFarmlyInterestModel interestModel
    ) external;

    function getVaultInterestModel(
        address vault
    ) external view returns (IFarmlyInterestModel);

    function uniPerformanceFee() external view returns (uint24);

    function vaultPerformanceFee() external view returns (uint24);

    function liquidationPerformanceFee() external view returns (uint24);

    function liquidationThreshold() external view returns (uint24);

    function feeAddress() external view returns (address);
}
