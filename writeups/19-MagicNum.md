# 19-MagicNum
```
构造一个编译器合约:
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SolverDeployer {
    function deploy() public returns (address) {
        bytes memory bytecode = hex"600a600c600039600a6000f3602a60005260206000f3";
        address solver;
        
        assembly {
            solver := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        
        return solver;
    }
}
# 1. 部署 SolverDeployer //其实这一步 同时创建了两个合约
forge create src/19-MagicNum/SolverDeployer.sol:SolverDeployer \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast
Deployed to: 0xCcbc18F6978FFD0211377851fBB3cEAdc0A9998b

# 2. 调用 deploy() 创建 solver 合约
cast send --rpc-url $sepolia_rpc --private-key $PRIVATE_KEY $SolverDeployer_ADDRESS 
=>tx: 0xee91ec904447236c48a3831415960a344f0dce868e9519e2e2b8c6e73697d542
计算地址:0xf86983085f15DC9b6CB14e84E1d26E7EE8282a2F
SOLVER=$(cast compute-address --nonce 1 0xCcbc18F6978FFD0211377851fBB3cEAdc0A9998b)
或者使用cast run fork:
luckyme@macdeMacBook-Pro ethernaut % cast run 0xee91ec904447236c48a3831415960a344f0dce868e9519e2e2b8c6e73697d542 \
    --rpc-url $sepolia_rpc
Executing previous transactions from the block.
Traces:
  [34475] 0xCcbc18F6978FFD0211377851fBB3cEAdc0A9998b::deploy()
    ├─ [2024] → new <unknown>@0xf86983085f15DC9b6CB14e84E1d26E7EE8282a2F
    │   └─ ← [Return] 10 bytes of code
    └─ ← [Return] 0x000000000000000000000000f86983085f15dc9b6cb14e84e1d26e7ee8282a2f


Transaction successfully executed.
Gas used: 55539
=> SOLVER_Address=0xf86983085f15DC9b6CB14e84E1d26E7EE8282a2F

# 3. 测试
cast call $SOLVER_Address "whatIsTheMeaningOfLife()" --rpc-url $sepolia_rpc

# 4. 设置到 MagicNum
cast send $MagicNum_ADDRESS "setSolver(address)" $SOLVER_Address \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY

```

### 考察知识点
- 编译后的字节码会有几百字节，远超 10 字节限制需要手写EVM 字节码缩小codesize.
- 了解运行时代码 (runtime code)
```
// 运行时代码（10 字节）
602a    // PUSH1 0x2a (将 42 推入栈)
6000    // PUSH1 0x00 (内存位置 0)
52      // MSTORE (将 42 存储到内存位置 0)
6020    // PUSH1 0x20 (返回数据长度 32 字节)
6000    // PUSH1 0x00 (内存位置 0)
f3      // RETURN (返回内存中的数据)

// 总共：10 字节 ✓
```
- 了解创建代码 (creation code)  负责将运行时代码复制到内存,返回运行时代码
```
// 创建代码
600a    // PUSH1 0x0a (运行时代码长度 = 10 字节)
600c    // PUSH1 0x0c (运行时代码在创建代码中的起始位置)
6000    // PUSH1 0x00 (内存目标位置)
39      // CODECOPY (复制代码到内存)
600a    // PUSH1 0x0a (返回数据长度 = 10 字节)
6000    // PUSH1 0x00 (内存位置)
f3      // RETURN (返回运行时代码)

// 运行时代码（紧跟在创建代码后面）
602a60005260206000f3

// 完整字节码：
// 创建代码：600a600c600039600a6000f3
// 运行时代码：602a60005260206000f3
```
- 完整十六进制：0x600a600c600039600a6000f3602a60005260206000f3 (也叫原始字节码,包含了创建代码以及运行时代码)

### 彩蛋
Awesome work! You’re halfway through Ethernaut and getting pretty good at breaking things. Working as a Blockchain Security Researcher at OpenZeppelin could be fun... https://grnh.se/fdbf1c043us