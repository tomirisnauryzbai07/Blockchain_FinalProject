// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {OracleAdapter} from "../../src/OracleAdapter.sol";
import {OutcomeToken} from "../../src/OutcomeToken.sol";
import {PredictionMarket} from "../../src/PredictionMarket.sol";
import {PredictionMarketFactory} from "../../src/PredictionMarketFactory.sol";
import {TreasuryVault} from "../../src/TreasuryVault.sol";
import {MockV3Aggregator} from "../../src/mocks/MockV3Aggregator.sol";
import {MarketTypes} from "../../src/libraries/MarketTypes.sol";

contract Trader {
    function buy(PredictionMarket market, uint8 outcome, uint256 collateralIn) external returns (uint256) {
        return market.buy(outcome, collateralIn);
    }

    function sell(PredictionMarket market, uint8 outcome, uint256 sharesIn) external returns (uint256) {
        return market.sell(outcome, sharesIn);
    }

    function redeem(PredictionMarket market, uint256 sharesIn) external returns (uint256) {
        return market.redeemWinningShares(sharesIn);
    }

    function withdraw(PredictionMarket market) external returns (uint256) {
        return market.withdrawCollateral();
    }
}

contract PredictionMarketFactoryTest {
    address internal constant OWNER = address(0xA11CE);
    address internal constant COLLATERAL = address(0xCA11);

    OutcomeToken internal outcomeToken;
    OracleAdapter internal oracle;
    TreasuryVault internal treasury;
    PredictionMarketFactory internal factory;
    MockV3Aggregator internal btcFeed;
    bytes32 internal constant QUESTION_ID = keccak256("btc-100k-2026");

    function setUp() public {
        outcomeToken = new OutcomeToken(address(this));
        oracle = new OracleAdapter(address(this), 30 days);
        treasury = new TreasuryVault(address(this));
        factory = new PredictionMarketFactory(address(this), address(treasury), address(outcomeToken));
        btcFeed = new MockV3Aggregator(8, 110_000e8);
        oracle.setBinaryMarketConfig(QUESTION_ID, address(btcFeed), 100_000e8, true);
    }

    function testCreateMarketTracksAddress() public {
        PredictionMarket market = _createMarket();
        MarketTypes.MarketMetadata memory details = factory.marketDetails(address(market));

        require(factory.marketCount() == 1, "bad count");
        require(factory.marketAt(0) == address(market), "bad market");
        require(market.FACTORY() == address(factory), "bad factory");
        require(details.feeBps == 30, "bad fee bps");
        require(details.oracleQuestionId == QUESTION_ID, "bad question id");
        require(!details.deterministic, "should not be deterministic");
    }

    function testCreateMarketDeterministicStoresSalt() public {
        MarketTypes.MarketConfig memory config = _config();
        bytes32 salt = keccak256("market-1");

        address market = factory.createMarketDeterministic(config, salt);
        MarketTypes.MarketMetadata memory details = factory.marketDetails(market);

        require(factory.marketBySalt(salt) == market, "salt missing");
        require(factory.marketCount() == 1, "count mismatch");
        require(details.deterministic, "missing deterministic flag");
        require(details.deploymentSalt == salt, "missing salt");
    }

    function testBuyMintsOutcomeShares() public {
        PredictionMarket market = _createMarket();
        Trader trader = new Trader();
        (uint256 previewShares, uint256 fee) = market.quoteBuy(market.OUTCOME_YES(), 1_000 ether);

        uint256 shares = trader.buy(market, market.OUTCOME_YES(), 1_000 ether);

        require(shares > 0, "no shares");
        require(shares == previewShares, "quote mismatch");
        require(fee == 3 ether, "bad fee");
        require(market.collateralPool() == 1_000 ether, "pool mismatch");
        require(outcomeToken.balanceOf(market.OUTCOME_YES(), address(trader)) == shares, "balance mismatch");
        require(market.outcomeSupply(market.OUTCOME_YES()) == shares, "supply mismatch");
    }

    function testSellCreatesWithdrawableCollateral() public {
        PredictionMarket market = _createMarket();
        Trader trader = new Trader();

        uint256 bought = trader.buy(market, market.OUTCOME_NO(), 2_000 ether);
        (uint256 quotedOut,) = market.quoteSell(market.OUTCOME_NO(), bought / 2);
        uint256 soldOut = trader.sell(market, market.OUTCOME_NO(), bought / 2);
        uint256 withdrawn = trader.withdraw(market);

        require(soldOut == quotedOut, "sell quote mismatch");
        require(soldOut > 0, "no collateral out");
        require(withdrawn == soldOut, "withdraw mismatch");
        require(market.pendingCollateral(address(trader)) == 0, "pending not cleared");
    }

    function testResolveAndRedeemWinningShares() public {
        PredictionMarket market = _createMarket();
        Trader yesTrader = new Trader();
        Trader noTrader = new Trader();

        uint256 yesShares = yesTrader.buy(market, market.OUTCOME_YES(), 1_500 ether);
        noTrader.buy(market, market.OUTCOME_NO(), 500 ether);

        market.beginResolution();
        market.resolve();

        uint256 redeemOut = yesTrader.redeem(market, yesShares / 2);
        uint256 withdrawn = yesTrader.withdraw(market);

        require(market.winningOutcome() == market.OUTCOME_YES(), "wrong winner");
        require(market.totalWinningSharesAtResolution() == yesShares, "snapshot mismatch");
        require(redeemOut > 0, "no redeem out");
        require(withdrawn == redeemOut, "wrong withdraw");
    }

    function testOracleAdapterReturnsZeroBelowThreshold() public {
        btcFeed.updateAnswer(90_000e8);

        (int256 answer, uint256 updatedAt) = oracle.latestAnswer(QUESTION_ID);

        require(answer == 0, "expected no");
        require(updatedAt == block.timestamp, "wrong timestamp");
    }

    function testSnapshotExposesAccruedFees() public {
        PredictionMarket market = _createMarket();
        Trader trader = new Trader();
        trader.buy(market, market.OUTCOME_YES(), 1_000 ether);

        MarketTypes.MarketSnapshot memory data = market.snapshot();

        require(data.accruedFees == 3 ether, "bad accrued fees");
        require(data.collateralPool == 1_000 ether, "bad snapshot pool");
    }

    function _createMarket() internal returns (PredictionMarket market) {
        market = PredictionMarket(factory.createMarket(_config()));
        outcomeToken.setMinter(address(market), true);
    }

    function _config() internal view returns (MarketTypes.MarketConfig memory) {
        return
            MarketTypes.MarketConfig({
                question: "Will BTC be above 100k on 2026-12-31?",
                endTime: uint64(block.timestamp),
                resolveWindow: 1 days,
                feeBps: 30,
                collateralToken: COLLATERAL,
                oracleAdapter: address(oracle),
                oracleQuestionId: QUESTION_ID
            });
    }
}
