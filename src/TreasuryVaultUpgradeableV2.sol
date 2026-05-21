// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TreasuryVaultUpgradeableV1} from "./TreasuryVaultUpgradeableV1.sol";

contract TreasuryVaultUpgradeableV2 is TreasuryVaultUpgradeableV1 {
    uint256 public emergencyWithdrawalDelay;

    event EmergencyWithdrawalDelaySet(uint256 newDelay);

    function setEmergencyWithdrawalDelay(uint256 newDelay) external onlyOwner {
        emergencyWithdrawalDelay = newDelay;
        emit EmergencyWithdrawalDelaySet(newDelay);
    }

    function version() external pure override returns (string memory) {
        return "V2";
    }
}
