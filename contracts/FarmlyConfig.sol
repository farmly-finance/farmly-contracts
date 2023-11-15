pragma solidity >=0.5.0;

import "./interfaces/IFarmlyConfig.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract FarmlyConfig is IFarmlyConfig, Ownable {
    /// @inheritdoc IFarmlyConfig
    uint24 public override uniPerformanceFee = 100000;
    /// @inheritdoc IFarmlyConfig
    uint24 public override vaultPerformanceFee = 200000;
    /// @inheritdoc IFarmlyConfig
    uint24 public override liquidationPerformanceFee = 100000;
    /// @inheritdoc IFarmlyConfig
    uint24 public override liquidationThreshold = 875000;
    /// @inheritdoc IFarmlyConfig
    address public override feeAddress =
        0x626c414DBE7c333eCd5b5C5F3B8E725c99C6f848;

    /// @notice Stores interest models of vaults
    mapping(address => IFarmlyInterestModel) private vaultInterestModel;

    /// @inheritdoc IFarmlyConfig
    function getVaultInterestModel(
        address vault
    ) public view override returns (IFarmlyInterestModel) {
        return vaultInterestModel[vault];
    }

    /// @inheritdoc IFarmlyConfig
    function setVaultInterestModel(
        address vault,
        IFarmlyInterestModel interestModel
    ) public override onlyOwner {
        vaultInterestModel[vault] = interestModel;
        emit VaultInterestModel(vault, address(interestModel));
    }
}
