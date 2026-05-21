// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TreasuryVault {
    address public owner;
    uint256 public accountedFees;

    event FeesAccounted(uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, "NOT_OWNER");
    }

    constructor(address initialOwner) {
        owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function accountFees(uint256 amount) external onlyOwner {
        accountedFees += amount;
        emit FeesAccounted(amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
