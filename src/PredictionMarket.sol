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
    uint256 public accruedFees;
    uint256 public totalWinningSharesAtResolution;
    uint256 public resolvedCollateralPool;
    uint8 public winningOutcome;

    mapping(uint8 outcome => uint256 supply) public outcomeSupply;
    mapping(address account => uint256 amount) public pendingCollateral;

    event SharesPurchased(address indexed buyer, uint8 indexed outcome, uint256 collateralIn, uint256 sharesOut);
    event SharesSold(address indexed seller, uint8 indexed outcome, uint256 sharesIn, uint256 collateralOut);
    event MarketStateChanged(MarketTypes.MarketState previousState, MarketTypes.MarketState nextState);
    event MarketResolved(uint8 indexed outcome, uint256 timestamp);
    event WinningsRedeemed(address indexed redeemer, uint256 sharesBurned, uint256 collateralOut);
    event CollateralWithdrawn(address indexed account, uint256 amount);

    error MarketClosed();
    error InvalidOutcome();
    error ResolutionTooEarly();
    error InvalidOracleAnswer();
    error InsufficientLiquidity();
    error NothingToWithdraw();
    error InvalidState();

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

        uint256 fee = _feeFor(collateralIn);
        sharesOut = _quoteShares(outcome, collateralIn - fee);
        accruedFees += fee;
        collateralPool += collateralIn;

        if (outcome == OUTCOME_YES) {
            yesReserve += sharesOut;
        } else {
            noReserve += sharesOut;
        }

        outcomeSupply[outcome] += sharesOut;
        OUTCOME_TOKEN.mint(msg.sender, outcome, sharesOut);
        emit SharesPurchased(msg.sender, outcome, collateralIn, sharesOut);
    }

    function sell(uint8 outcome, uint256 sharesIn) external returns (uint256 collateralOut) {
        if (state != MarketTypes.MarketState.Trading) revert MarketClosed();
        if (outcome > OUTCOME_YES) revert InvalidOutcome();
        require(sharesIn > 0, "ZERO_SHARES");

        collateralOut = _quoteCollateralOut(outcome, sharesIn);
        if (collateralOut > collateralPool) revert InsufficientLiquidity();

        uint256 fee = _feeFor(collateralOut);
        collateralOut -= fee;
        accruedFees += fee;
        collateralPool -= collateralOut;

        if (outcome == OUTCOME_YES) {
            yesReserve -= sharesIn;
        } else {
            noReserve -= sharesIn;
        }

        outcomeSupply[outcome] -= sharesIn;
        OUTCOME_TOKEN.burn(msg.sender, outcome, sharesIn);
        pendingCollateral[msg.sender] += collateralOut;

        emit SharesSold(msg.sender, outcome, sharesIn, collateralOut);
    }

    function beginResolution() external {
        if (block.timestamp < marketConfig.endTime) revert ResolutionTooEarly();
        if (state != MarketTypes.MarketState.Trading) revert InvalidState();
        _setState(MarketTypes.MarketState.PendingResolution);
    }

    function resolve() external {
        if (state != MarketTypes.MarketState.PendingResolution) revert InvalidState();

        (int256 answer,) = IOracleAdapter(marketConfig.oracleAdapter).latestAnswer(marketConfig.oracleQuestionId);
        if (answer != 0 && answer != 1) revert InvalidOracleAnswer();

        winningOutcome = answer == 0 ? OUTCOME_NO : OUTCOME_YES;
        totalWinningSharesAtResolution = outcomeSupply[winningOutcome];
        resolvedCollateralPool = collateralPool;
        _setState(MarketTypes.MarketState.Resolved);
        emit MarketResolved(winningOutcome, block.timestamp);
    }

    function redeemWinningShares(uint256 sharesIn) external returns (uint256 collateralOut) {
        if (state != MarketTypes.MarketState.Resolved) revert InvalidState();
        require(sharesIn > 0, "ZERO_SHARES");
        require(totalWinningSharesAtResolution > 0, "NO_WINNING_SHARES");

        collateralOut = (resolvedCollateralPool * sharesIn) / totalWinningSharesAtResolution;

        outcomeSupply[winningOutcome] -= sharesIn;
        OUTCOME_TOKEN.burn(msg.sender, winningOutcome, sharesIn);
        pendingCollateral[msg.sender] += collateralOut;

        emit WinningsRedeemed(msg.sender, sharesIn, collateralOut);
    }

    function withdrawCollateral() external returns (uint256 amount) {
        amount = pendingCollateral[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        pendingCollateral[msg.sender] = 0;
        emit CollateralWithdrawn(msg.sender, amount);
    }

    function snapshot() external view returns (MarketTypes.MarketSnapshot memory) {
        return
            MarketTypes.MarketSnapshot({
                state: state,
                yesShares: yesReserve,
                noShares: noReserve,
                collateralPool: collateralPool,
                accruedFees: accruedFees,
                winningOutcome: winningOutcome
            });
    }

    function quoteBuy(uint8 outcome, uint256 collateralIn) external view returns (uint256 sharesOut, uint256 fee) {
        if (outcome > OUTCOME_YES) revert InvalidOutcome();
        fee = _feeFor(collateralIn);
        sharesOut = _quoteShares(outcome, collateralIn - fee);
    }

    function quoteSell(uint8 outcome, uint256 sharesIn) external view returns (uint256 collateralOut, uint256 fee) {
        if (outcome > OUTCOME_YES) revert InvalidOutcome();
        collateralOut = _quoteCollateralOut(outcome, sharesIn);
        fee = _feeFor(collateralOut);
        collateralOut -= fee;
    }

    function _quoteShares(uint8 outcome, uint256 collateralIn) internal view returns (uint256) {
        uint256 activeReserve = outcome == OUTCOME_YES ? yesReserve : noReserve;
        return (collateralIn * 1e18) / (activeReserve + 1e18);
    }

    function _quoteCollateralOut(uint8 outcome, uint256 sharesIn) internal view returns (uint256) {
        uint256 activeReserve = outcome == OUTCOME_YES ? yesReserve : noReserve;
        require(activeReserve > sharesIn, "INSUFFICIENT_RESERVE");
        return (sharesIn * (activeReserve + 1e18)) / 1e18;
    }

    function _feeFor(uint256 amount) internal view returns (uint256) {
        return (amount * marketConfig.feeBps) / BPS_DENOMINATOR;
    }

    function _setState(MarketTypes.MarketState nextState) internal {
        MarketTypes.MarketState previousState = state;
        state = nextState;
        emit MarketStateChanged(previousState, nextState);
    }
}
