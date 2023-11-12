pragma solidity >=0.5.0;
import "./vault/IFarmlyVaultImmutables.sol";
import "./vault/IFarmlyVaultState.sol";
import "./vault/IFarmlyVaultDerivedState.sol";
import "./vault/IFarmlyVaultActions.sol";
import "./vault/IFarmlyVaultOwnerActions.sol";
import "./vault/IFarmlyVaultEvents.sol";

/// @title The interface for the Farmly Vault
/// @notice Functions for lending via Farmly Finance.
interface IFarmlyVault is
    IFarmlyVaultImmutables,
    IFarmlyVaultState,
    IFarmlyVaultDerivedState,
    IFarmlyVaultActions,
    IFarmlyVaultOwnerActions,
    IFarmlyVaultEvents
{

}
