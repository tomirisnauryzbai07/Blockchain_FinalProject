// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IOracleAdapter} from "./interfaces/IOracleAdapter.sol";

contract OracleAdapter is IOracleAdapter {
    struct AnswerData {
        int256 answer;
        uint256 updatedAt;
    }

    address public owner;
    uint256 public immutable STALE_AFTER;
    mapping(bytes32 questionId => AnswerData) internal answers;

    event AnswerSet(bytes32 indexed questionId, int256 answer, uint256 updatedAt);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, "NOT_OWNER");
    }

    constructor(address initialOwner, uint256 staleAfterSeconds) {
        owner = initialOwner;
        STALE_AFTER = staleAfterSeconds;
    }

    function setAnswer(bytes32 questionId, int256 answer, uint256 updatedAt) external onlyOwner {
        answers[questionId] = AnswerData({answer: answer, updatedAt: updatedAt});
        emit AnswerSet(questionId, answer, updatedAt);
    }

    function latestAnswer(bytes32 questionId) external view returns (int256 answer, uint256 updatedAt) {
        AnswerData memory data = answers[questionId];
        require(data.updatedAt != 0, "MISSING_ANSWER");
        require(block.timestamp - data.updatedAt <= STALE_AFTER, "STALE_ANSWER");
        return (data.answer, data.updatedAt);
    }
}
