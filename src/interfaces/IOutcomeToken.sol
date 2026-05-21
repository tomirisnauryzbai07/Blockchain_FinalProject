// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IOutcomeToken {
    function mint(address to, uint256 outcomeId, uint256 amount) external;
    function burn(address from, uint256 outcomeId, uint256 amount) external;
}

