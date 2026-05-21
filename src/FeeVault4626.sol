// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract FeeVault4626 is ERC4626, Ownable {
    using SafeERC20 for ERC20;

    event YieldDonated(address indexed caller, uint256 assets);

    constructor(ERC20 asset_, address initialOwner)
        ERC20("Forecast Fee Vault Share", "fVAULT")
        ERC4626(asset_)
        Ownable(initialOwner)
    {}

    function donateYield(uint256 assets) external onlyOwner {
        require(assets > 0, "ZERO_ASSETS");
        ERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);
        emit YieldDonated(msg.sender, assets);
    }
}
