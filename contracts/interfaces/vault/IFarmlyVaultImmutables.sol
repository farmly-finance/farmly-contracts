pragma solidity >=0.5.0;

/// @title Vault state that never changes
/// @notice These parameters are fixed for a vault, they are fixed forever.
/// Methods will always return the same value.
interface IFarmlyVaultImmutables {
    /// @notice Token for use in lending&borrowing
    /// @return The token contract address
    function token() external view returns (address);

    /// @notice Config contract for use of protocol configrations
    /// @return Farmly config contract
    function farmlyConfig() external view returns (address);
}
