// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PredictionMarketFactory} from "../../src/PredictionMarketFactory.sol";
import {OracleAdapter} from "../../src/OracleAdapter.sol";
import {OutcomeToken} from "../../src/OutcomeToken.sol";
import {TreasuryVault} from "../../src/TreasuryVault.sol";
import {MarketTypes} from "../../src/libraries/MarketTypes.sol";

contract PredictionMarketFactoryTest {
    function testScaffoldCompiles() external pure returns (bool) {
        return true;
    }

    function exampleConfig(address collateral, address oracle) external pure returns (MarketTypes.MarketConfig memory) {
        return
            MarketTypes.MarketConfig({
                question: "Will BTC be above 100k on 2026-12-31?",
                endTime: 1_800_000_000,
                resolveWindow: 1 days,
                feeBps: 30,
                collateralToken: collateral,
                oracleAdapter: oracle,
                oracleQuestionId: keccak256("btc-100k-2026")
            });
    }

    function exampleDeployment(
        address owner
    )
        external
        returns (
            PredictionMarketFactory factory,
            OutcomeToken outcomeToken,
            OracleAdapter oracle,
            TreasuryVault treasury
        )
    {
        outcomeToken = new OutcomeToken(owner);
        oracle = new OracleAdapter(owner, 1 days);
        treasury = new TreasuryVault(owner);
        factory = new PredictionMarketFactory(owner, address(treasury), address(outcomeToken));
    }
}
