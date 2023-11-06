pragma solidity >=0.5.0;

/// @title The interface for the Farmly Interest Model
/// @notice The Farmly Interest Model makes managing the Vault's interest model easier
/// @dev For all percentages, 1% = 1e18.

interface IFarmlyInterestModel {
    /// @notice The first range for utilization
    /// @return The top of the range
    function UTILIZATION_RANGE_1() external view returns (uint256);

    /// @notice The second range for utilization
    /// @return The top of the range
    function UTILIZATION_RANGE_2() external view returns (uint256);

    /// @notice The third range for utilization
    /// @return The top of the range
    function UTILIZATION_RANGE_3() external view returns (uint256);

    /// @notice Returns utilization for the given debt and total value
    /// @param debt Total debt amount
    /// @param total Total supplied amount to vault
    /// @return utilization Utilization ratio for given values
    function getUtilization(
        uint256 debt,
        uint256 total
    ) external view returns (uint256 utilization);

    /// @notice Returns borrowing apr for the given debt and total value
    /// @dev Implementation of the interest model determined for the vault.
    /// @param debt Total debt amount
    /// @param total Total supplied amount to vault
    /// @return borrowAPR Borrowing APR in one seconds
    function getBorrowAPR(
        uint256 debt,
        uint256 total
    ) external view returns (uint256 borrowAPR);
}
