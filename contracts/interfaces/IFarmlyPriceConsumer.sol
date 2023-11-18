pragma solidity >=0.5.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Contract interface used to get current prices of assets
/// @notice This contract uses Chainlink Oracle contracts to trust the accuracy of the data.
/// @dev Converts all prices to 1e18 decimal.
/// 1 USD = 1e18;
interface IFarmlyPriceConsumer {
    struct FarmlyAggregator {
        AggregatorV3Interface aggregator;
        uint256 decimals;
    }

    /// @notice Storages Chainlink Aggregators for each tokens.
    /// @return Returns Chainlink Aggregator and price decimals.
    function aggregators(
        address
    ) external view returns (AggregatorV3Interface, uint256);

    /// @notice Returns the current price for the token.
    /// @dev The current token price is calculated using the data of the latest round.
    /// @param token Contract address of the token.
    /// @return price Price of the token.
    function getPrice(address token) external view returns (uint256 price);

    /// @notice Calculates the usd equivalent of the token amount.
    /// @dev For the reaching current price of token, getPrice() function can be use.
    /// USDValue = token price * token amount.
    /// @param token Contract address of the token.
    /// @param amount Amount of given token.
    /// @return USDValue Dollar value of calculated.
    function calcUSDValue(
        address token,
        uint256 amount
    ) external view returns (uint256 USDValue);

    /// @notice Set Chainlink Aggregator for the token
    /// @dev Can only be called by the owner.
    /// @param token The token for set aggregator
    /// @param aggregator The aggregator struct
    function setTokenAggregator(
        address token,
        FarmlyAggregator memory aggregator
    ) external;
}
