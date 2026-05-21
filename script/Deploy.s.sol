// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GovernanceToken} from "../src/GovernanceToken.sol";
import {OracleAdapter} from "../src/OracleAdapter.sol";
import {OutcomeToken} from "../src/OutcomeToken.sol";
import {PredictionMarketFactory} from "../src/PredictionMarketFactory.sol";
import {TreasuryVault} from "../src/TreasuryVault.sol";

contract DeployScaffold {
    function deploy(
        address owner,
        uint256 staleAfterSeconds
    )
        external
        returns (
            GovernanceToken governanceToken,
            OutcomeToken outcomeToken,
            OracleAdapter oracleAdapter,
            TreasuryVault treasuryVault,
            PredictionMarketFactory factory
        )
    {
        governanceToken = new GovernanceToken(owner);
        outcomeToken = new OutcomeToken(owner);
        oracleAdapter = new OracleAdapter(owner, staleAfterSeconds);
        treasuryVault = new TreasuryVault(owner);
        factory = new PredictionMarketFactory(owner, address(treasuryVault), address(outcomeToken));
    }
}

