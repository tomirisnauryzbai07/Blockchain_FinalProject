// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FeeVault4626} from "../../src/FeeVault4626.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract FeeVault4626Test {
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);

    MockERC20 internal assetToken;
    FeeVault4626 internal vault;

    function setUp() public {
        assetToken = new MockERC20("Mock USD", "mUSD", 18);
        vault = new FeeVault4626(assetToken, address(this));

        assetToken.mint(address(this), 1_000_000 ether);
        assetToken.mint(ALICE, 1_000_000 ether);
        assetToken.mint(BOB, 1_000_000 ether);

        assetToken.approve(address(vault), type(uint256).max);
    }

    function testDepositMintsMatchingSharesAtStart() public {
        uint256 shares = vault.deposit(100 ether, address(this));

        require(shares == 100 ether, "bad shares");
        require(vault.totalAssets() == 100 ether, "bad assets");
        require(vault.balanceOf(address(this)) == 100 ether, "bad balance");
    }

    function testMintPullsExpectedAssetsAtStart() public {
        uint256 assets = vault.mint(250 ether, address(this));

        require(assets == 250 ether, "bad assets in");
        require(vault.totalAssets() == 250 ether, "bad total assets");
        require(vault.balanceOf(address(this)) == 250 ether, "bad share balance");
    }

    function testWithdrawBurnsShares() public {
        vault.deposit(300 ether, address(this));
        uint256 burnedShares = vault.withdraw(120 ether, address(this), address(this));

        require(burnedShares == 120 ether, "bad burned shares");
        require(vault.totalAssets() == 180 ether, "bad remaining assets");
        require(vault.balanceOf(address(this)) == 180 ether, "bad remaining shares");
    }

    function testRedeemReturnsAssets() public {
        vault.deposit(175 ether, address(this));
        uint256 assetsOut = vault.redeem(75 ether, address(this), address(this));

        require(assetsOut == 75 ether, "bad assets out");
        require(vault.totalAssets() == 100 ether, "bad post redeem assets");
        require(vault.balanceOf(address(this)) == 100 ether, "bad post redeem shares");
    }

    function testDonateYieldIncreasesAssetsPerShare() public {
        vault.deposit(100 ether, address(this));
        uint256 previewBefore = vault.previewRedeem(100 ether);

        vault.donateYield(40 ether);
        uint256 previewAfter = vault.previewRedeem(100 ether);

        require(previewBefore == 100 ether, "bad preview before");
        require(previewAfter == 140 ether, "bad preview after");
        require(vault.totalAssets() == 140 ether, "bad total assets");
    }
}
