// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {VestingWallet} from "../src/VestingWallet.sol";

contract VestingWalletTest is Test {
    VestingWallet internal wallet;
    address internal beneficiary = address(0xBEEF);
    uint64 internal constant START = 1_000_000;
    uint64 internal constant CLIFF = 30 days;
    uint64 internal constant DURATION = 365 days;

    function setUp() public {
        wallet = new VestingWallet(beneficiary, START, CLIFF, DURATION);
        vm.deal(address(wallet), 365 ether);
        vm.warp(START);
    }

    function test_NothingVestedBeforeCliff() public {
        vm.warp(START + CLIFF - 1);
        assertEq(wallet.vestedAmount(uint64(block.timestamp)), 0);
    }

    function test_VestsLinearlyAfterCliff() public {
        vm.warp(START + DURATION / 2);
        // 365 ether * 182.5 days / 365 days, integer division
        assertEq(wallet.vestedAmount(uint64(block.timestamp)), 182.5 ether);
    }

    function test_FullyVestedAtEnd() public {
        vm.warp(START + DURATION);
        assertEq(wallet.vestedAmount(uint64(block.timestamp)), 365 ether);
    }

    function test_ReleaseMovesOnlyVested() public {
        vm.warp(START + DURATION / 2);
        uint256 before = beneficiary.balance;
        vm.prank(beneficiary);
        wallet.release();
        assertEq(beneficiary.balance - before, 182.5 ether);
        assertEq(address(wallet).balance, 365 ether - 182.5 ether);
    }

    function test_RevertWhenNotBeneficiary() public {
        vm.warp(START + DURATION);
        vm.prank(address(0x1234));
        vm.expectRevert(VestingWallet.NotBeneficiary.selector);
        wallet.release();
    }

    function test_RevertWhenNothingToRelease() public {
        vm.prank(beneficiary);
        vm.expectRevert(VestingWallet.NothingToRelease.selector);
        wallet.release();
    }

    function testFuzz_VestedNeverExceedsBalance(uint64 t) public {
        vm.warp(START);
        uint256 vested = wallet.vestedAmount(t);
        assertLe(vested, address(wallet).balance);
    }

    function test_ConstructorRejectsBadInput() public {
        vm.expectRevert(VestingWallet.ZeroBeneficiary.selector);
        new VestingWallet(address(0), START, 0, DURATION);
        vm.expectRevert(VestingWallet.CliffExceedsDuration.selector);
        new VestingWallet(beneficiary, START, DURATION + 1, DURATION);
    }
}
