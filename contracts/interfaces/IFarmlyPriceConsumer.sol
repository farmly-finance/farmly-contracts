pragma solidity >=0.5.0;

interface IFarmlyPriceConsumer {
    function getPrice(address token) external view returns (uint256 price);
}
