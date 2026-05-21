// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IOracleAdapter} from "./interfaces/IOracleAdapter.sol";

contract OracleAdapter is IOracleAdapter, Ownable {
    struct BinaryMarketOracleConfig {
        address feed;
        int256 threshold;
        bool outcomeIfGreaterOrEqual;
        bool isConfigured;
    }

    uint256 public immutable STALE_AFTER;

    mapping(bytes32 questionId => BinaryMarketOracleConfig config) internal configs;

    event OracleConfigSet(
        bytes32 indexed questionId,
        address indexed feed,
        int256 threshold,
        bool outcomeIfGreaterOrEqual
    );

    constructor(address initialOwner, uint256 staleAfterSeconds) Ownable(initialOwner) {
        STALE_AFTER = staleAfterSeconds;
    }

    function setBinaryMarketConfig(
        bytes32 questionId,
        address feed,
        int256 threshold,
        bool outcomeIfGreaterOrEqual
    ) external onlyOwner {
        require(feed != address(0), "ZERO_FEED");

        configs[questionId] = BinaryMarketOracleConfig({
            feed: feed,
            threshold: threshold,
            outcomeIfGreaterOrEqual: outcomeIfGreaterOrEqual,
            isConfigured: true
        });

        emit OracleConfigSet(questionId, feed, threshold, outcomeIfGreaterOrEqual);
    }

    function latestAnswer(bytes32 questionId) external view returns (int256 answer, uint256 updatedAt) {
        BinaryMarketOracleConfig memory config = configs[questionId];
        require(config.isConfigured, "MISSING_CONFIG");

        (, int256 latestPrice,, uint256 latestUpdatedAt,) = AggregatorV3Interface(config.feed).latestRoundData();
        require(latestUpdatedAt != 0, "MISSING_ANSWER");
        require(block.timestamp - latestUpdatedAt <= STALE_AFTER, "STALE_ANSWER");

        bool outcome = latestPrice >= config.threshold;
        if (!config.outcomeIfGreaterOrEqual) {
            outcome = !outcome;
        }

        return (outcome ? int256(1) : int256(0), latestUpdatedAt);
    }

    function oracleConfig(
        bytes32 questionId
    ) external view returns (address feed, int256 threshold, bool outcomeIfGreaterOrEqual, bool isConfigured) {
        BinaryMarketOracleConfig memory config = configs[questionId];
        return (config.feed, config.threshold, config.outcomeIfGreaterOrEqual, config.isConfigured);
    }
}

