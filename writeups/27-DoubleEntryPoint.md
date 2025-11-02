# 27-DoubleEntryPoint
```
# 1. 获取合约地址（从新实例）
export NEW_INSTANCE=0xB7ED48d71A303cdF8bcFc659E02fF9bE92df3c9B  # DET 实例地址
export FORTA_ADDRESS=$(cast call $NEW_INSTANCE "forta()(address)" --rpc-url $sepolia_rpc)
export VAULT_ADDRESS=$(cast call $NEW_INSTANCE "cryptoVault()(address)" --rpc-url $sepolia_rpc)
export LEGACY_TOKEN=$(cast call $NEW_INSTANCE "delegatedFrom()(address)" --rpc-url $sepolia_rpc)
export DET_ADDRESS=$NEW_INSTANCE

# 2. 部署检测机器人（传入 Vault 地址）
forge create src/27-Forta/FortaDetectionBot.sol:FortaDetectionBot \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --constructor-args $VAULT_ADDRESS
# Deployed to: 0x8Dca7d1b9C97b8cD93950aaBc0A38318C9FBa964
export BOT_ADDRESS=<部署地址>

# 3. 注册检测机器人到 Forta
cast send $FORTA_ADDRESS "setDetectionBot(address)" $BOT_ADDRESS \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY

# 4. 验证注册成功
cast call $FORTA_ADDRESS "usersDetectionBots(address)(address)" $YOUR_ADDRESS --rpc-url $sepolia_rpc

# 5. 测试防御（应该被阻止并 revert）
cast send $VAULT_ADDRESS "sweepToken(address)" $LEGACY_TOKEN \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --gas-limit 500000 \
    -vv
# 预期结果: revert "Alert has been triggered, reverting"

# 执行链路
vault.sweepToken(LegacyToken)
  → LegacyToken.transfer()
    → DET.delegateTransfer(to, value, vault)  ← origSender = vault
      → fortaNotify modifier
        → forta.notify(player, msg.data)
          → detectionBot.handleTransaction(player, msgData)
            ├─ 从 msgData 中提取 origSender (使用 msgData.offset + 0x44)
            ├─ 检测到 origSender == cryptoVault
            └─ forta.raiseAlert(player)  ✅ 触发警报
      → 检查 botRaisedAlerts 增加
      → revert("Alert has been triggered, reverting")
```

### 考察点
- **双重入口漏洞**：代币委托升级机制中，旧代币（LGT）委托给新代币（DET），如果 Vault 清理 LGT，实际会转走 DET
- **Calldata 解析**：理解 `bytes calldata` 参数的内存布局，使用 `msgData.offset` 正确读取参数
- **Assembly 数据读取**：`calldataload(add(msgData.offset, 0x44))` 读取第三个参数 `origSender`
- **防御机制**：通过检测 `origSender == vault` 来防御双重入口攻击，在 `fortaNotify` 修饰符中触发 revert
