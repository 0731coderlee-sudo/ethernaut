// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/01-HelloEthernaut/Instance.sol";

/**
 * @title HelloEthernautTest
 * @notice POC for Ethernaut Level 03 (00) - Hello Ethernaut
 * @dev Demonstrates basic contract interaction and storage reading
 */
contract HelloEthernautTest is Test {
    Instance public instance;
    address public player;

    string constant PASSWORD = "ethernaut0";

    function setUp() public {
        player = address(0x1);

        // Deploy the Instance contract with a password
        instance = new Instance(PASSWORD);

        console.log("=== Setup Complete ===");
        console.log("Instance deployed at:", address(instance));
        console.log("Player address:", player);
    }

    /**
     * @notice Test following the contract hints step by step
     */
    function testSolveByFollowingHints() public {
        console.log("\n=== Method 1: Following Contract Hints ===");

        // Step 1: Call info()
        string memory hint1 = instance.info();
        console.log("Step 1 - info():", hint1);

        // Step 2: Call info1()
        string memory hint2 = instance.info1();
        console.log("Step 2 - info1():", hint2);

        // Step 3: Call info2("hello")
        string memory hint3 = instance.info2("hello");
        console.log("Step 3 - info2('hello'):", hint3);

        // Step 4: Get infoNum
        uint8 num = instance.infoNum();
        console.log("Step 4 - infoNum:", num);
        assertEq(num, 42, "infoNum should be 42");

        // Step 5: Call info42()
        string memory hint4 = instance.info42();
        console.log("Step 5 - info42():", hint4);

        // Step 6: Get theMethodName
        string memory methodName = instance.theMethodName();
        console.log("Step 6 - theMethodName:", methodName);

        // Step 7: Call method7123949()
        string memory hint5 = instance.method7123949();
        console.log("Step 7 - method7123949():", hint5);

        // Step 8: Get password
        string memory password = instance.password();
        console.log("Step 8 - Retrieved password:", password);

        // Step 9: Authenticate
        vm.prank(player);
        instance.authenticate(password);

        // Step 10: Verify success
        bool cleared = instance.getCleared();
        console.log("Step 9 - Cleared:", cleared);
        assertTrue(cleared, "Challenge should be cleared");

        console.log("\n[SUCCESS] Challenge completed!");
    }

    /**
     * @notice Test direct authentication
     */
    function testDirectAuthentication() public {
        console.log("\n=== Method 2: Direct Authentication ===");

        // Read password directly
        string memory password = instance.password();
        console.log("Retrieved password:", password);
        assertEq(password, PASSWORD, "Password should match");

        // Authenticate
        vm.prank(player);
        instance.authenticate(password);

        // Verify
        assertTrue(instance.getCleared(), "Should be authenticated");
        console.log("Authentication successful!");
    }

    /**
     * @notice Test reading password from storage
     */
    function testReadPasswordFromStorage() public {
        console.log("\n=== Method 3: Reading from Storage ===");

        // Password is at slot 0
        bytes32 slot0 = vm.load(address(instance), bytes32(uint256(0)));
        console.log("Storage slot 0 (raw):");
        console.logBytes32(slot0);

        // For short strings, length*2 is in the last byte
        uint256 length = uint256(uint8(slot0[31])) / 2;
        console.log("Password length:", length);

        // Extract password
        bytes memory passwordBytes = new bytes(length);
        for (uint i = 0; i < length; i++) {
            passwordBytes[i] = slot0[i];
        }
        string memory retrievedPassword = string(passwordBytes);
        console.log("Retrieved password:", retrievedPassword);

        // Authenticate
        vm.prank(player);
        instance.authenticate(retrievedPassword);

        assertTrue(instance.getCleared(), "Should be authenticated");
        console.log("Storage-based authentication successful!");
    }

    /**
     * @notice Test wrong password (negative test)
     */
    function testWrongPassword() public {
        console.log("\n=== Negative Test: Wrong Password ===");

        vm.prank(player);
        instance.authenticate("wrongpassword");

        assertFalse(instance.getCleared(), "Should NOT be cleared");
        console.log("Wrong password correctly rejected");
    }

    /**
     * @notice Test info2 with wrong parameter
     */
    function testInfo2WrongParameter() public view{
        console.log("\n=== Test: info2 with wrong parameter ===");

        string memory result = instance.info2("wrong");
        console.log("Result:", result);

        assertEq(result, "Wrong parameter.", "Should return error message");
    }

    /**
     * @notice Educational test about blockchain transparency
     */
    function testBlockchainTransparency() public view{
        console.log("\n=== Blockchain Transparency Lesson ===");
        console.log("");
        console.log("Key Lesson: ALL data on blockchain is public!");
        console.log("");
        console.log("Even 'private' variables can be read from storage.");
        console.log("Never store sensitive data (passwords, keys) on-chain.");
        console.log("");
        console.log("Public variable 'password':", instance.password());
        console.log("This is accessible to everyone!");
        console.log("");
        console.log("In real applications:");
        console.log("- Use off-chain storage for sensitive data");
        console.log("- Use cryptographic commitments");
        console.log("- Use zero-knowledge proofs");
        console.log("- Never store plaintext secrets");
    }
}
