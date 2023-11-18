pragma solidity >=0.5.0;

import "./interfaces/IFarmlyPriceConsumer.sol";
import "./libraries/FarmlyFullMath.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract FarmlyPriceConsumer is IFarmlyPriceConsumer, Ownable {
    /// @inheritdoc IFarmlyPriceConsumer
    mapping(address => FarmlyAggregator) public override aggregators;

    /// Initial state of aggregators
    constructor() {
        aggregators[
            0x067ADb4d5Ff41068A92D8d6dc103679eEdD07519
        ] = FarmlyAggregator(
            AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e),
            8
        );

        aggregators[
            0x3ec2e8d6F81cb2b871e451fD368bD9c2b68eA09B
        ] = FarmlyAggregator(
            AggregatorV3Interface(0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7),
            8
        );
    }

    /// @inheritdoc IFarmlyPriceConsumer
    function getPrice(
        address token
    ) public view override returns (uint256 price) {
        FarmlyAggregator memory aggregator = aggregators[token];
        (, int token0Answer, , , ) = aggregator.aggregator.latestRoundData();

        price = (uint256(token0Answer) * 1e18) / (10 ** aggregator.decimals);
    }

    /// @inheritdoc IFarmlyPriceConsumer
    function calcUSDValue(
        address token,
        uint256 amount
    ) public view override returns (uint256 USDValue) {
        uint256 price = getPrice(token);
        USDValue = FarmlyFullMath.mulDiv(price, amount, 1e18);
    }

    function setTokenAggregator(
        address token,
        FarmlyAggregator memory aggregator
    ) public override onlyOwner {
        aggregators[token] = aggregator;
    }
}
