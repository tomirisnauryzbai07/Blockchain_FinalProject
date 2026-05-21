// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IOracleAdapter {
    function latestAnswer(bytes32 questionId) external view returns (int256 answer, uint256 updatedAt);
}

