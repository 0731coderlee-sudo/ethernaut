# Force Attack - 部署和执行步骤

## 攻击原理

通过 `selfdestruct` 强制向 Force 合约发送 ETH，即使该合约没有 `receive()` 或 `fallback()` 函数。

### EVM 层面原理

```
正常转账:
  CALL → 触发 receive/fallback → 可以被 revert 拒绝

selfdestruct:
  SELFDESTRUCT 操作码 → 直接修改目标地址的 balance → 无法拒绝
```

## 执行步骤

### 1. 编译合约

```bash
forge build
```

### 2. 部署攻击合约

```bash
forge create src/08-Force/AttackForce.sol:AttackForce \
  --rpc-url $sepolia_rpc \
  --private-key $PRIVATE_KEY \
  --constructor-args $Force_ADDRESS
```

保存输出的合约地址到环境变量：

```bash
export AttackForce_ADDRESS=0x...
```

### 3. 执行攻击脚本

```bash
node script/Force.js
```

## 脚本执行流程

1. 检查 Force 合约当前余额（应该为 0）
2. 向 AttackForce 合约发送 0.001 ETH
3. 调用 `AttackForce.attack()` 触发 selfdestruct
4. 验证 Force 合约余额增加

## 其他强制发送 ETH 的方法

### 方法 2: 预计算合约地址

```solidity
// 1. 计算未来的合约地址
address futureAddr = address(uint160(uint(keccak256(abi.encodePacked(
    bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x01)
)))));

// 2. 先发送 ETH
payable(futureAddr).transfer(1 ether);

// 3. 再部署合约（它会继承余额）
new Force();
```

### 方法 3: Coinbase 奖励（仅矿工）

矿工可以在挖矿配置中设置：
```
coinbase = <Force 合约地址>
```

区块奖励会直接发送到该地址，无法拒绝。

## 安全启示

⚠️ **永远不要假设合约余额为 0**

错误的代码示例：
```solidity
contract Vulnerable {
    function withdraw() external {
        require(address(this).balance == 10 ether, "Wrong amount");
        // 攻击者可以用 selfdestruct 发送 1 wei，导致条件永远不满足
    }
}
```

正确的做法：
```solidity
contract Secure {
    uint256 public depositedAmount;

    function deposit() external payable {
        depositedAmount += msg.value;  // 追踪预期余额
    }

    function withdraw() external {
        require(depositedAmount >= 10 ether, "Not enough");
        // 使用内部变量，而不是 address(this).balance
    }
}
```
