// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";

contract MockV3Aggregator is AggregatorV3Interface {
    uint8 public immutable override decimals;

    uint80 public latestRoundId;
    int256 public latestAnswerValue;
    uint256 public latestStartedAt;
    uint256 public latestUpdatedAt;
    uint80 public latestAnsweredInRound;

    constructor(uint8 decimals_, int256 initialAnswer) {
        decimals = decimals_;
        updateAnswer(initialAnswer);
    }

    function updateAnswer(int256 newAnswer) public {
        latestRoundId += 1;
        latestAnswerValue = newAnswer;
        latestStartedAt = block.timestamp;
        latestUpdatedAt = block.timestamp;
        latestAnsweredInRound = latestRoundId;
    }

    function updateRoundData(
        uint80 roundId,
        int256 newAnswer,
        uint256 startedAt,
        uint256 updatedAt
    ) external {
        latestRoundId = roundId;
        latestAnswerValue = newAnswer;
        latestStartedAt = startedAt;
        latestUpdatedAt = updatedAt;
        latestAnsweredInRound = roundId;
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (latestRoundId, latestAnswerValue, latestStartedAt, latestUpdatedAt, latestAnsweredInRound);
    }
}

