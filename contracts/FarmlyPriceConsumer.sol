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
            0x917D6e003A6D7BAb2E17c1c8E27e771e30fFF938
        ] = FarmlyAggregator(
            AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612),
            8
        );

        aggregators[
            0xB5Ed8C7Cef3EA95574187ddc52a56F2Fe6b38ab3
        ] = FarmlyAggregator(
            AggregatorV3Interface(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3),
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

    /// @inheritdoc IFarmlyPriceConsumer
    function setTokenAggregator(
        address token,
        FarmlyAggregator memory aggregator
    ) public override onlyOwner {
        aggregators[token] = aggregator;
    }
}
