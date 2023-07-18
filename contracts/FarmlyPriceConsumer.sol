pragma solidity >=0.5.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FarmlyPriceConsumer is Ownable {
    struct FarmlyAggregator {
        AggregatorV3Interface aggregator;
        uint256 decimals;
    }

    mapping(address => FarmlyAggregator) public aggregators;

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

    function getPrice(address token) public view returns (uint256 price) {
        FarmlyAggregator memory aggregator = aggregators[token];
        (, int token0Answer, , , ) = aggregator.aggregator.latestRoundData();

        price =
            (uint256(token0Answer) * 10 ** 18) /
            (10 ** aggregator.decimals);
    }
}
