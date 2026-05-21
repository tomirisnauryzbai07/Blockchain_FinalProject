// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract OutcomeToken {
    string public constant URI = "ipfs://prediction-market/{id}.json";
    address public owner;

    mapping(uint256 outcomeId => mapping(address account => uint256 balance)) public balanceOf;
    mapping(address account => bool authorizedMinter) public isMinter;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event MinterSet(address indexed account, bool allowed);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    modifier onlyMinter() {
        _onlyMinter();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, "NOT_OWNER");
    }

    function _onlyMinter() internal view {
        require(isMinter[msg.sender], "NOT_MINTER");
    }

    constructor(address initialOwner) {
        owner = initialOwner;
    }

    function setMinter(address account, bool allowed) external onlyOwner {
        isMinter[account] = allowed;
        emit MinterSet(account, allowed);
    }

    function mint(address to, uint256 outcomeId, uint256 amount) external onlyMinter {
        balanceOf[outcomeId][to] += amount;
        emit TransferSingle(msg.sender, address(0), to, outcomeId, amount);
    }

    function burn(address from, uint256 outcomeId, uint256 amount) external onlyMinter {
        uint256 currentBalance = balanceOf[outcomeId][from];
        require(currentBalance >= amount, "INSUFFICIENT_BALANCE");

        unchecked {
            balanceOf[outcomeId][from] = currentBalance - amount;
        }

        emit TransferSingle(msg.sender, from, address(0), outcomeId, amount);
    }
}
