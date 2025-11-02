// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function raiseAlert(address user) external;
}

contract FortaDetectionBot is IDetectionBot {
    address private immutable cryptoVault;
    
    constructor(address _vault) {
        cryptoVault = _vault;
    }
    
    function handleTransaction(address user, bytes calldata msgData) external override {
        // delegateTransfer(address to, uint256 value, address origSender)
        // msgData 布局:
        // 0x00-0x04: 函数选择器 (4 bytes)
        // 0x04-0x24: to (32 bytes)
        // 0x24-0x44: value (32 bytes)
        // 0x44-0x64: origSender (32 bytes) ← 目标参数
        
        // 从 msgData 中提取 origSender（第三个参数）
        // 跳过：selector (4 bytes) + to (32 bytes) + value (32 bytes) = 68 bytes (0x44)
        address origSender;
        assembly {
            // msgData 是 calldata，需要从 msgData 的起始位置计算偏移
            origSender := calldataload(add(msgData.offset, 0x44))
        }
        
        // 如果 origSender 是 vault，触发警报
        if (origSender == cryptoVault) {
            IForta(msg.sender).raiseAlert(user);
        }
    }
}