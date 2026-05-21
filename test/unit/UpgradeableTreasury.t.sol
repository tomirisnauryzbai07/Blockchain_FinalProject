// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TreasuryVaultUpgradeableV1} from "../../src/TreasuryVaultUpgradeableV1.sol";
import {TreasuryVaultUpgradeableV2} from "../../src/TreasuryVaultUpgradeableV2.sol";

contract UpgradeableTreasuryTest {
    function testProxyInitializesV1State() public returns (TreasuryVaultUpgradeableV1 vault) {
        TreasuryVaultUpgradeableV1 implementation = new TreasuryVaultUpgradeableV1();
        bytes memory initData = abi.encodeCall(TreasuryVaultUpgradeableV1.initialize, (address(this)));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        vault = TreasuryVaultUpgradeableV1(address(proxy));
        vault.accountFees(123);

        require(vault.accountedFees() == 123, "bad fees");
        require(keccak256(bytes(vault.version())) == keccak256("V1"), "bad version");
    }

    function testV2ImplementationExposesExtendedState() public returns (TreasuryVaultUpgradeableV2 v2) {
        v2 = new TreasuryVaultUpgradeableV2();
        require(keccak256(bytes(v2.version())) == keccak256("V2"), "bad v2");
    }
}
