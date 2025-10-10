# 03 - Hello Ethernaut (Level 0)

## 关卡信息
- **难度**: ⭐ (入门)
- **合约**: Instance.sol
- **Solidity版本**: ^0.8.0
- **目标**: 通过一系列提示找到密码并完成认证
- **类型**: 教程关卡

## 关卡概述

这是Ethernaut的第一个关卡（Level 0），主要目的是教会玩家：
1. 如何与智能合约交互
2. 如何调用合约函数
3. 如何读取合约状态
4. 理解区块链的透明性

**这不是一个安全漏洞关卡**，而是一个教学关卡。

## 合约分析

### 合约结构
```solidity
contract Instance {
    string public password;           // 公开的密码
    uint8 public infoNum = 42;       // 线索：下一个方法的编号
    string public theMethodName;      // 线索：方法名称
    bool private cleared = false;     // 是否已通过认证
}
```

### 交互流程

合约设计了一个"寻宝游戏"式的交互流程：

```
info()
  ↓
info1()
  ↓
info2("hello")
  ↓
infoNum (返回42)
  ↓
info42()
  ↓
theMethodName (返回"method7123949")
  ↓
method7123949()
  ↓
password (读取密码)
  ↓
authenticate(password)
  ↓
完成！
```

## 解决方法

### 方法1: 按照提示逐步完成（推荐新手）

**步骤1**: 调用 `info()`
```javascript
await contract.info()
// "You will find what you need in info1()."
```

**步骤2**: 调用 `info1()`
```javascript
await contract.info1()
// 'Try info2(), but with "hello" as a parameter.'
```

**步骤3**: 调用 `info2("hello")`
```javascript
await contract.info2("hello")
// "The property infoNum holds the number of the next info method to call."
```

**步骤4**: 读取 `infoNum`
```javascript
await contract.infoNum()
// 42
```

**步骤5**: 调用 `info42()`
```javascript
await contract.info42()
// "theMethodName is the name of the next method."
```

**步骤6**: 读取 `theMethodName`
```javascript
await contract.theMethodName()
// "The method name is method7123949."
```

**步骤7**: 调用 `method7123949()`
```javascript
await contract.method7123949()
// "If you know the password, submit it to authenticate()."
```

**步骤8**: 读取 `password`
```javascript
const password = await contract.password()
console.log(password) // "ethernaut0"
```

**步骤9**: 调用 `authenticate(password)`
```javascript
await contract.authenticate(password)
```

**步骤10**: 验证是否完成
```javascript
await contract.getCleared()
// true
```

### 方法2: 直接读取密码（理解原理）

因为`password`是`public`变量，可以直接读取：

```javascript
const password = await contract.password()
await contract.authenticate(password)
```

### 方法3: 从区块链浏览器读取

1. 在区块浏览器中查看合约部署交易
2. 查看构造函数的input data
3. 解析出密码参数
4. 调用authenticate

### 方法4: 读取Storage（高级）

```javascript
// 密码存储在slot 0
const slot0 = await web3.eth.getStorageAt(contractAddress, 0)
const password = web3.utils.hexToAscii(slot0)
await contract.authenticate(password)
```

## 核心知识点

### 1. 区块链透明性

**关键概念**: 区块链上的所有数据都是公开的

```solidity
string public password;   // ❌ 任何人都可以读取
string private password;  // ❌ 仍然可以通过storage读取
```

**正确认识**:
- `public`: 自动生成getter函数
- `private`: 只是限制其他合约访问，不代表隐私
- **所有状态变量都可以通过读取storage获取**

### 2. 函数可见性

```solidity
function info() public pure returns (string memory)
//              ^^^^^^ ^^^^
//              可见性  状态可变性
```

- `public`: 任何人都可以调用
- `pure`: 不读取也不修改状态
- `view`: 只读取状态，不修改
- `没有修饰符`: 会修改状态

### 3. ABI与合约交互

通过ABI (Application Binary Interface)，我们可以：
- 调用合约函数
- 读取public状态变量
- 监听事件

### 4. Storage布局

```
Slot 0: password (string)
Slot 1: infoNum (uint8)
Slot 2: theMethodName (string)
Slot 3: cleared (bool)
```

即使变量是`private`，也可以通过slot编号读取。

## 安全启示

### 不要在链上存储敏感信息

**错误做法**:
```solidity
contract Vulnerable {
    string private secretKey;  // ❌ 不安全！
    string private password;   // ❌ 不安全！
    uint256 private seed;      // ❌ 不安全！
}
```

**正确做法**:

1. **使用哈希而非明文**
```solidity
contract Better {
    bytes32 public passwordHash;

    constructor(string memory _password) {
        passwordHash = keccak256(abi.encodePacked(_password));
    }

    function authenticate(string memory _password) public view returns (bool) {
        return keccak256(abi.encodePacked(_password)) == passwordHash;
    }
}
```

2. **使用Commit-Reveal模式**
```solidity
contract CommitReveal {
    mapping(address => bytes32) public commits;

    function commit(bytes32 hash) public {
        commits[msg.sender] = hash;
    }

    function reveal(string memory password, bytes32 salt) public {
        require(
            commits[msg.sender] == keccak256(abi.encodePacked(password, salt)),
            "Invalid reveal"
        );
    }
}
```

3. **使用链下签名**
```solidity
contract OffChainAuth {
    address public signer;

    function authenticate(bytes memory signature) public {
        // 验证签名而非存储密码
        address recovered = recoverSigner(signature);
        require(recovered == signer, "Invalid signature");
    }
}
```

4. **使用零知识证明**
```solidity
// 使用zk-SNARKs证明知道某个秘密
// 而不暴露秘密本身
```

## 最佳实践

### 设计合约时的考虑

1. **假设所有数据都是公开的**
   - 不要依赖`private`关键字保护敏感数据
   - 考虑使用加密或哈希

2. **使用事件记录重要操作**
```solidity
event Authenticated(address indexed user);

function authenticate(string memory passkey) public {
    if (checkPassword(passkey)) {
        cleared = true;
        emit Authenticated(msg.sender);
    }
}
```

3. **提供清晰的接口**
```solidity
/// @notice Authenticates the caller with a password
/// @param passkey The password to authenticate with
/// @return success Whether authentication succeeded
function authenticate(string memory passkey)
    public
    returns (bool success)
```

## 工具和技术

### 读取合约数据的工具

1. **Web3.js / Ethers.js**
```javascript
const password = await contract.password()
```

2. **Foundry Cast**
```bash
cast call <address> "password()(string)"
cast storage <address> 0
```

3. **区块浏览器**
- Etherscan
- 查看合约代码
- 查看交易数据

4. **Foundry Forge**
```solidity
vm.load(address, slot)
```

## Foundry测试

### 运行测试
```bash
# 运行所有测试
forge test --match-contract HelloEthernautTest -vvv

# 运行特定测试
forge test --match-test testSolveByFollowingHints -vvvv

# 查看详细日志
forge test --match-test testBlockchainTransparency -vvvv
```

### 测试输出示例
```
Running 1 test for test/03-HelloEthernaut.t.sol:HelloEthernautTest
[PASS] testSolveByFollowingHints() (gas: 123456)
Logs:
  Step 1 - info(): You will find what you need in info1().
  Step 2 - info1(): Try info2(), but with "hello" as a parameter.
  ...
  [SUCCESS] Challenge completed!
```

## 总结

### 学到了什么

1. ✅ 如何与智能合约交互
2. ✅ 如何调用函数和读取状态
3. ✅ 区块链数据的透明性
4. ✅ public vs private的真正含义
5. ✅ 不要在链上存储敏感信息

### 关键要点

- **区块链是透明的**: 所有数据都是公开的
- **Private不是隐私**: 只是访问控制，不是加密
- **使用正确的模式**: Commit-reveal、签名验证等
- **测试和验证**: 使用Foundry等工具充分测试

## 相关资源

- [Ethernaut官方](https://ethernaut.openzeppelin.com/)
- [Solidity Storage Layout](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html)
- [Solidity Function Visibility](https://docs.soliditylang.org/en/latest/contracts.html#visibility-and-getters)
- [Foundry Book](https://book.getfoundry.sh/)
