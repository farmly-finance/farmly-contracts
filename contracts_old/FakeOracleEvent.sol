pragma solidity >=0.5.0;

contract FakeOracleEvent {
    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    uint256 public roundId;

    function emitPrice(int256 _price) public {
        emit AnswerUpdated(_price, roundId, block.timestamp);
        roundId++;
    }
}
