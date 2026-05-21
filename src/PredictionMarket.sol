// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IOracleAdapter} from "./interfaces/IOracleAdapter.sol";
import {IOutcomeToken} from "./interfaces/IOutcomeToken.sol";
import {MarketTypes} from "./libraries/MarketTypes.sol";

contract PredictionMarket {
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint8 public constant OUTCOME_NO = 0;
    uint8 public constant OUTCOME_YES = 1;

    address public immutable FACTORY;
    address public immutable TREASURY;
    IOutcomeToken public immutable OUTCOME_TOKEN;

    MarketTypes.MarketConfig public marketConfig;
    MarketTypes.MarketState public state;

    uint256 public yesReserve;
    uint256 public noReserve;
    uint256 public collateralPool;
    uint8 public winningOutcome;

    event SharesPurchased(address indexed buyer, uint8 indexed outcome, uint256 collateralIn, uint256 sharesOut);
    event MarketStateChanged(MarketTypes.MarketState previousState, MarketTypes.MarketState nextState);
    event MarketResolved(uint8 indexed outcome, uint256 timestamp);

    error MarketClosed();
    error InvalidOutcome();
    error ResolutionTooEarly();
    error InvalidOracleAnswer();

    constructor(
        address treasury_,
        address outcomeToken_,
        MarketTypes.MarketConfig memory config
    ) {
        require(treasury_ != address(0), "ZERO_TREASURY");
        require(outcomeToken_ != address(0), "ZERO_OUTCOME_TOKEN");

        FACTORY = msg.sender;
        TREASURY = treasury_;
        OUTCOME_TOKEN = IOutcomeToken(outcomeToken_);
        marketConfig = config;
        state = MarketTypes.MarketState.Trading;

        yesReserve = 1e18;
        noReserve = 1e18;
    }

    function buy(uint8 outcome, uint256 collateralIn) external returns (uint256 sharesOut) {
        if (state != MarketTypes.MarketState.Trading) revert MarketClosed();
        if (outcome > OUTCOME_YES) revert InvalidOutcome();
        require(collateralIn > 0, "ZERO_COLLATERAL");

        sharesOut = _quoteShares(outcome, collateralIn);
        collateralPool += collateralIn;

        if (outcome == OUTCOME_YES) {
            yesReserve += sharesOut;
        } else {
            noReserve += sharesOut;
        }

        OUTCOME_TOKEN.mint(msg.sender, outcome, sharesOut);
        emit SharesPurchased(msg.sender, outcome, collateralIn, sharesOut);
    }

    function beginResolution() external {
        if (block.timestamp < marketConfig.endTime) revert ResolutionTooEarly();
        _setState(MarketTypes.MarketState.PendingResolution);
    }

    function resolve() external {
        if (state != MarketTypes.MarketState.PendingResolution) revert MarketClosed();

        (int256 answer,) = IOracleAdapter(marketConfig.oracleAdapter).latestAnswer(marketConfig.oracleQuestionId);
        if (answer != 0 && answer != 1) revert InvalidOracleAnswer();

        winningOutcome = answer == 0 ? OUTCOME_NO : OUTCOME_YES;
        _setState(MarketTypes.MarketState.Resolved);
        emit MarketResolved(winningOutcome, block.timestamp);
    }

    function snapshot() external view returns (MarketTypes.MarketSnapshot memory) {
        return
            MarketTypes.MarketSnapshot({
                state: state,
                yesShares: yesReserve,
                noShares: noReserve,
                collateralPool: collateralPool,
                winningOutcome: winningOutcome
            });
    }

    function _quoteShares(uint8 outcome, uint256 collateralIn) internal view returns (uint256) {
        uint256 fee = (collateralIn * marketConfig.feeBps) / BPS_DENOMINATOR;
        uint256 netCollateral = collateralIn - fee;

        uint256 activeReserve = outcome == OUTCOME_YES ? yesReserve : noReserve;
        return (netCollateral * 1e18) / (activeReserve + 1e18);
    }

    function _setState(MarketTypes.MarketState nextState) internal {
        MarketTypes.MarketState previousState = state;
        state = nextState;
        emit MarketStateChanged(previousState, nextState);
    }
}
