// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "openzeppelin-contracts/lib/forge-std/src/Test.sol";
import {MockV3Aggregator} from "../../src/mocks/MockV3Aggregator.sol";
import {OracleAdapter} from "../../src/OracleAdapter.sol";
import {OutcomeToken} from "../../src/OutcomeToken.sol";
import {PredictionMarket} from "../../src/PredictionMarket.sol";
import {PredictionMarketFactory} from "../../src/PredictionMarketFactory.sol";
import {TreasuryVault} from "../../src/TreasuryVault.sol";
import {MarketTypes} from "../../src/libraries/MarketTypes.sol";

contract PredictionMarketFuzzTest is Test {
    address internal constant COLLATERAL = address(0xCA11);
    bytes32 internal constant QUESTION_ID = keccak256("btc-100k-2026");

    OutcomeToken internal outcomeToken;
    OracleAdapter internal oracle;
    TreasuryVault internal treasury;
    PredictionMarketFactory internal factory;
    PredictionMarket internal market;
    MockV3Aggregator internal btcFeed;

    function setUp() public {
        outcomeToken = new OutcomeToken(address(this));
        oracle = new OracleAdapter(address(this), 30 days);
        treasury = new TreasuryVault(address(this));
        factory = new PredictionMarketFactory(address(this), address(treasury), address(outcomeToken));
        btcFeed = new MockV3Aggregator(8, 110_000e8);
        oracle.setBinaryMarketConfig(QUESTION_ID, address(btcFeed), 100_000e8, true);

        market = PredictionMarket(factory.createMarket(_config()));
        outcomeToken.setMinter(address(market), true);
    }

    function testFuzzQuoteBuyMatchesBuy(uint8 outcomeSeed, uint256 collateralIn) public {
        uint8 outcome = outcomeSeed % 2;
        collateralIn = bound(collateralIn, 1, 1_000_000 ether);

        (uint256 quotedShares, uint256 fee) = market.quoteBuy(outcome, collateralIn);
        uint256 actualShares = market.buy(outcome, collateralIn);

        assertEq(actualShares, quotedShares);
        assertEq(fee, (collateralIn * 30) / 10_000);
        assertGt(actualShares, 0);
    }

    function testFuzzSnapshotAccruedFeesNeverExceedCollateral(uint8 outcomeSeed, uint256 collateralIn) public {
        uint8 outcome = outcomeSeed % 2;
        collateralIn = bound(collateralIn, 1, 1_000_000 ether);

        market.buy(outcome, collateralIn);
        MarketTypes.MarketSnapshot memory data = market.snapshot();

        assertLe(data.accruedFees, data.collateralPool);
        assertEq(data.accruedFees, (collateralIn * 30) / 10_000);
    }

    function testFuzzSellQuoteMatchesWithdrawableCollateral(
        uint256 collateralIn,
        uint256 sellBps,
        uint8 outcomeSeed
    ) public {
        uint8 outcome = outcomeSeed % 2;
        collateralIn = bound(collateralIn, 2 ether, 1_000_000 ether);

        uint256 bought = market.buy(outcome, collateralIn);
        uint256 sharesToSell = bound((bought * sellBps) / 10_000, 1, bought);

        (uint256 quotedOut,) = market.quoteSell(outcome, sharesToSell);
        uint256 soldOut = market.sell(outcome, sharesToSell);

        assertEq(soldOut, quotedOut);
        assertEq(market.pendingCollateral(address(this)), soldOut);
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

