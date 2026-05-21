// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library MarketTypes {
    enum MarketState {
        Trading,
        PendingResolution,
        Resolved,
        Cancelled
    }

    struct MarketConfig {
        string question;
        uint64 endTime;
        uint64 resolveWindow;
        uint256 feeBps;
        address collateralToken;
        address oracleAdapter;
        bytes32 oracleQuestionId;
    }

    struct MarketSnapshot {
        MarketState state;
        uint256 yesShares;
        uint256 noShares;
        uint256 collateralPool;
        uint256 accruedFees;
        uint8 winningOutcome;
    }

    struct MarketMetadata {
        string question;
        uint64 endTime;
        uint64 resolveWindow;
        uint256 feeBps;
        address collateralToken;
        address oracleAdapter;
        bytes32 oracleQuestionId;
        bool deterministic;
        bytes32 deploymentSalt;
    }
}
