// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "openzeppelin-contracts/lib/forge-std/src/Test.sol";
import {FeeVault4626} from "../../src/FeeVault4626.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract FeeVault4626FuzzTest is Test {
    FeeVault4626 internal vault;
    MockERC20 internal assetToken;

    function setUp() public {
        assetToken = new MockERC20("Mock USD", "mUSD", 18);
        vault = new FeeVault4626(assetToken, address(this));
        assetToken.mint(address(this), 10_000_000 ether);
        assetToken.approve(address(vault), type(uint256).max);
    }

    function testFuzzDepositThenRedeemReturnsNoMoreThanAssetsIn(uint256 assets) public {
        assets = bound(assets, 1, 1_000_000 ether);

        uint256 shares = vault.deposit(assets, address(this));
        uint256 assetsOut = vault.redeem(shares, address(this), address(this));

        assertLe(assetsOut, assets);
        assertEq(vault.totalAssets(), 0);
    }

    function testFuzzDonateYieldImprovesPreviewRedeem(uint256 depositAssets, uint256 donationAssets) public {
        depositAssets = bound(depositAssets, 1 ether, 1_000_000 ether);
        donationAssets = bound(donationAssets, 1 ether, 1_000_000 ether);

        uint256 shares = vault.deposit(depositAssets, address(this));
        uint256 previewBefore = vault.previewRedeem(shares);

        vault.donateYield(donationAssets);
        uint256 previewAfter = vault.previewRedeem(shares);

        assertGe(previewAfter, previewBefore);
        assertEq(vault.totalAssets(), depositAssets + donationAssets);
    }
}

