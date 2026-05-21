// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import {FeeVault4626} from "../src/FeeVault4626.sol";
import {ForecastGovernor} from "../src/ForecastGovernor.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {OracleAdapter} from "../src/OracleAdapter.sol";
import {OutcomeToken} from "../src/OutcomeToken.sol";
import {PredictionMarketFactory} from "../src/PredictionMarketFactory.sol";
import {TreasuryVault} from "../src/TreasuryVault.sol";
import {TreasuryVaultUpgradeableV1} from "../src/TreasuryVaultUpgradeableV1.sol";
import {TreasuryVaultUpgradeableV2} from "../src/TreasuryVaultUpgradeableV2.sol";

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

    function deployUpgradeableTreasury(
        address owner
    )
        external
        returns (
            TreasuryVaultUpgradeableV1 implementationV1,
            TreasuryVaultUpgradeableV2 implementationV2,
            ERC1967Proxy proxy
        )
    {
        implementationV1 = new TreasuryVaultUpgradeableV1();
        implementationV2 = new TreasuryVaultUpgradeableV2();

        bytes memory initData = abi.encodeCall(TreasuryVaultUpgradeableV1.initialize, (owner));
        proxy = new ERC1967Proxy(address(implementationV1), initData);
    }

    function deployFeeVault(ERC20 assetToken, address owner) external returns (FeeVault4626 vault) {
        vault = new FeeVault4626(assetToken, owner);
    }
}
