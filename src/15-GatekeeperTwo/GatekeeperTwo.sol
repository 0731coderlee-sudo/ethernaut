// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin); //eoa 通过外部合约调用
        _;
    }

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
            // 返回调用者的 codesize
        }
        require(x == 0);
        // 调用者不能是合约 codesize需要为0
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        //0xFFFFFFFFFFFFFFFF
        //a = uint64(bytes8(keccak256(abi.encodePacked(0x4A2578679C9a9901844380C7340e074045e75853)))) = 0xa095709b6399ea1
        //b= uint64(_gateKey)
        //a ^ b = 0xFFFFFFFFFFFFFFFF
        //=> b = 0xa095709b6399ea1 ^ 0xFFFFFFFFFFFFFFFF
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}