// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StdInvariant} from "openzeppelin-contracts/lib/forge-std/src/StdInvariant.sol";
import {Test} from "openzeppelin-contracts/lib/forge-std/src/Test.sol";
import {MockV3Aggregator} from "../../src/mocks/MockV3Aggregator.sol";
import {OracleAdapter} from "../../src/OracleAdapter.sol";
import {OutcomeToken} from "../../src/OutcomeToken.sol";
import {PredictionMarket} from "../../src/PredictionMarket.sol";
import {PredictionMarketFactory} from "../../src/PredictionMarketFactory.sol";
import {TreasuryVault} from "../../src/TreasuryVault.sol";
import {MarketTypes} from "../../src/libraries/MarketTypes.sol";

contract PredictionMarketHandler is Test {
    PredictionMarket internal market;
    uint256 public totalBoughtYes;
    uint256 public totalBoughtNo;

    constructor(PredictionMarket market_) {
        market = market_;
    }

    function buyYes(uint256 collateralIn) external {
        collateralIn = bound(collateralIn, 1, 100_000 ether);
        uint256 shares = market.buy(market.OUTCOME_YES(), collateralIn);
        totalBoughtYes += shares;
    }

    function buyNo(uint256 collateralIn) external {
        collateralIn = bound(collateralIn, 1, 100_000 ether);
        uint256 shares = market.buy(market.OUTCOME_NO(), collateralIn);
        totalBoughtNo += shares;
    }
}

contract PredictionMarketInvariantTest is StdInvariant, Test {
    address internal constant COLLATERAL = address(0xCA11);
    bytes32 internal constant QUESTION_ID = keccak256("btc-100k-2026");

    OutcomeToken internal outcomeToken;
    OracleAdapter internal oracle;
    TreasuryVault internal treasury;
    PredictionMarketFactory internal factory;
    PredictionMarket internal market;
    MockV3Aggregator internal btcFeed;
    PredictionMarketHandler internal handler;

    function setUp() public {
        outcomeToken = new OutcomeToken(address(this));
        oracle = new OracleAdapter(address(this), 30 days);
        treasury = new TreasuryVault(address(this));
        factory = new PredictionMarketFactory(address(this), address(treasury), address(outcomeToken));
        btcFeed = new MockV3Aggregator(8, 110_000e8);
        oracle.setBinaryMarketConfig(QUESTION_ID, address(btcFeed), 100_000e8, true);

        market = PredictionMarket(factory.createMarket(_config()));
        outcomeToken.setMinter(address(market), true);

        handler = new PredictionMarketHandler(market);
        targetContract(address(handler));
    }

    function invariantFeeNeverExceedsPool() public view {
        assertLe(market.accruedFees(), market.collateralPool());
    }

    function invariantOutcomeSupplyMatchesMintedShares() public view {
        assertEq(market.outcomeSupply(market.OUTCOME_YES()), handler.totalBoughtYes());
        assertEq(market.outcomeSupply(market.OUTCOME_NO()), handler.totalBoughtNo());
    }

    function invariantReservesStaySeeded() public view {
        assertGe(market.yesReserve(), 1e18);
        assertGe(market.noReserve(), 1e18);
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
