// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import {ForecastGovernor} from "../src/ForecastGovernor.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {OracleAdapter} from "../src/OracleAdapter.sol";
import {OutcomeToken} from "../src/OutcomeToken.sol";
import {PredictionMarketFactory} from "../src/PredictionMarketFactory.sol";
import {TreasuryVault} from "../src/TreasuryVault.sol";

contract DeployScaffold {
    uint256 public constant INITIAL_GOVERNANCE_SUPPLY = 1_000_000 ether;
    uint256 public constant TIMELOCK_DELAY = 2 days;

    function deploy(
        address owner,
        uint256 staleAfterSeconds
    )
        external
        returns (
            GovernanceToken governanceToken,
            TimelockController timelock,
            ForecastGovernor governor,
            OutcomeToken outcomeToken,
            OracleAdapter oracleAdapter,
            TreasuryVault treasuryVault,
            PredictionMarketFactory factory
        )
    {
        governanceToken = new GovernanceToken(owner);
        governanceToken.mint(owner, INITIAL_GOVERNANCE_SUPPLY);

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);
        timelock = new TimelockController(TIMELOCK_DELAY, proposers, executors, owner);
        governor = new ForecastGovernor(governanceToken, timelock, INITIAL_GOVERNANCE_SUPPLY / 100);

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), owner);

        governanceToken.transferOwnership(address(timelock));

        outcomeToken = new OutcomeToken(owner);
        oracleAdapter = new OracleAdapter(owner, staleAfterSeconds);
        treasuryVault = new TreasuryVault(owner);
        treasuryVault.transferOwnership(address(timelock));
        factory = new PredictionMarketFactory(owner, address(treasuryVault), address(outcomeToken));
    }
}
