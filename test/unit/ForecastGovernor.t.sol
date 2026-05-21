// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import {ForecastGovernor} from "../../src/ForecastGovernor.sol";
import {GovernanceToken} from "../../src/GovernanceToken.sol";

contract ForecastGovernorTest {
    function testGovernorUsesCourseParameters() public returns (ForecastGovernor governor) {
        GovernanceToken token = new GovernanceToken(address(this));
        token.mint(address(this), 1_000_000 ether);

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);

        TimelockController timelock = new TimelockController(2 days, proposers, executors, address(this));
        governor = new ForecastGovernor(token, timelock, 10_000 ether);

        require(governor.votingDelay() == 7_200, "bad voting delay");
        require(governor.votingPeriod() == 50_400, "bad voting period");
        require(governor.quorumNumerator() == 4, "bad quorum");
        require(governor.proposalThreshold() == 10_000 ether, "bad threshold");
        require(governor.timelock() == address(timelock), "bad timelock");
    }
}
