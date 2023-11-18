pragma solidity >=0.5.0;
import "./IFarmlyInterestModel.sol";

/// @title Interface to the Farmly Finance protocol configuration contract
/// @notice Configurations can only be changed by the Farmly Finance team.
/// @dev For all percentages, 1% = 10000
interface IFarmlyConfig {
    /// @notice Performance fee for Uniswap
    /// @dev Every Uniswap position opened on Farmly is subject to fees.
    /// This is the percentage commission on the trading fee earned by the position.
    /// @return Returns the fee rate.
    function uniPerformanceFee() external view returns (uint24);

    /// @notice Fee on interest paid to vaults
    /// @dev Every loan from Farmly's vaults carries interest.
    /// This represents the commission from the interest rate.
    /// @return Returns the fee rate.
    function vaultPerformanceFee() external view returns (uint24);

    /// @notice Liquidation performance fee
    /// @dev Positions that exceed the liquidation threshold are liquidated.
    /// This represents the performance fee for the liquidation process.
    /// @return Returns the fee rate.
    function liquidationPerformanceFee() external view returns (uint24);

    /// @notice Maximum liquidation threshold
    /// @dev Positions exceeding the liquidation threshold are liquidated.
    /// debt ratio = debt amount / total position amount
    /// @return Returns the liquidation threshold rate.
    function liquidationThreshold() external view returns (uint24);

    /// @notice Address for fees
    /// @dev All fees are payable to this address.
    /// @return Returns the fee address.
    function feeAddress() external view returns (address);

    /// @notice Contract address of vault's interest model
    /// @dev Interest rate models can be changed according to market conditions.
    /// Stores the current interest rate model for each vault.
    /// @param vault Vault's contract address
    /// @return Returns the vault's interest model contract address
    function getVaultInterestModel(
        address vault
    ) external view returns (IFarmlyInterestModel);

    /// @notice Setting the vault's interest model
    /// @dev Changes the interest rate model for the specified vault.
    /// Can only be called by the owner.
    /// @param vault Vault's contract address
    /// @param interestModel Contract address containing the interest model
    function setVaultInterestModel(
        address vault,
        IFarmlyInterestModel interestModel
    ) external;

    /// @notice Setting the performance fee for Uniswap
    /// @dev Can only be called by the owner.
    /// @param fee Performance fee rate
    function setUniPerformanceFee(uint24 fee) external;

    /// @notice Setting the fee on interest paid to vaults
    /// @dev Can only be called by the owner.
    /// @param fee Fee rate
    function setVaultPerformanceFee(uint24 fee) external;

    /// @notice Setting the liquidation performance fee
    /// @dev Can only be called by the owner.
    /// @param fee Liquidation performance fee rate
    function setLiquidationPerformanceFee(uint24 fee) external;

    /// @notice Setting the maximum liquidation threshold
    /// @dev Can only be called by the owner.
    /// @param threshold The liquidation threshold rate.
    function setLiquidationThreshold(uint24 threshold) external;

    /// @notice Setting the address for fees
    /// @dev Can only be called by the owner.
    /// @param _feeAddress The address for fees.
    function setFeeAddress(address _feeAddress) external;

    /// @notice Emitted when vault interest model is changed
    /// @param vault The vault contract address
    /// @param interestModel The interest model contract address
    event VaultInterestModel(address indexed vault, address interestModel);
}
