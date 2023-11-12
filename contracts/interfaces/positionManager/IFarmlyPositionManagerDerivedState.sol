pragma solidity >=0.5.0;

/// @title Position state that is not stored
/// @notice Contains derived states that do not need to be stored on the blockchain.
interface IFarmlyPositionManagerDerivedState {
    /// @notice Active positions length
    /// @return Returns active poisitions length
    function getActivePositionsLength() external view returns (uint256);

    /// @notice Returns the position dollar value
    /// @param positionID ID of the position
    /// @return token0USD The token0 amount in dollars of the position
    /// @return token1USD The token1 amount in dollars of the position
    /// @return totalUSD The total amount in dollars of the position
    function getPositionUSDValue(
        uint256 positionID
    )
        external
        view
        returns (uint256 token0USD, uint256 token1USD, uint256 totalUSD);

    /// @notice Debt ratio
    /// @dev debt ratio = dollar value of debt / dollar value of position
    /// @param positionID ID of the position
    /// @return debtRatio Returns total debt divided by total position amount
    function getDebtRatio(
        uint256 positionID
    ) external view returns (uint256 debtRatio);

    /// @notice Farmly Score
    /// @dev Represents the proximity of the debt ratio
    /// of the position to the liquidation threshold.
    /// It is valued above 10000. The closer it is to 10000,
    /// the closer it is to the liquidation threshold.
    /// flyScore = debtRatio * 10000 / liquidation threshold
    /// @param positionID ID of the position
    /// @return flyScore Calculated score
    function getFlyScore(
        uint256 positionID
    ) external view returns (uint256 flyScore);

    /// @notice Dollar value of position debt
    /// @param positionID ID of the position
    /// @return debt0USD Dollar value of token0 debt value
    /// @return debt1USD Dollar value of token1 debt value
    /// @return debtUSD Dollar value of debt value
    function getDebtUSDValue(
        uint256 positionID
    )
        external
        view
        returns (uint256 debt0USD, uint256 debt1USD, uint256 debtUSD);

    /// @notice Current leverage of position
    /// @dev Calculates the current leverage amount.
    /// leverage = total position value / total position value - total debt value
    /// @param positionID ID of the position
    /// @return leverage Returns current leverage
    function getCurrentLeverage(
        uint256 positionID
    ) external view returns (uint256 leverage);

    /// @notice Debt ratios of position
    /// @dev Calculates the total debt value of the position
    /// and calculates the ratio to the
    /// total debt value for each token.
    /// @param positionID ID of the position
    /// @return debtRatio0 Ratio of token0 debt value to total debt value
    /// @return debtRatio1 Ratio of token1 debt value to total debt value
    function getDebtRatios(
        uint256 positionID
    ) external view returns (uint256 debtRatio0, uint256 debtRatio1);

    /// @notice User positions in array
    /// @param user User wallet address
    /// @return Returns user's positions ids in array
    function getUserPositions(
        address user
    ) external view returns (uint256[] memory);
}
