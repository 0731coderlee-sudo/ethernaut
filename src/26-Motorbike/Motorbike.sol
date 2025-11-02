// SPDX-License-Identifier: MIT

pragma solidity <0.7.0;

import "openzeppelin-contracts-06/utils/Address.sol";
import "openzeppelin-contracts-06/proxy/Initializable.sol";

contract Motorbike {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    //eip1967 标准规定了代理合约中存储实现地址的存储位置
    struct AddressSlot {
        address value;
    }

    // Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
    constructor(address _logic) public {
        require(Address.isContract(_logic), "ERC1967: new implementation is not a contract");
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = _logic;
        //在代理合约中初始化实现合约 实际上是让实现合约的 initialize() 函数在代理合约的上下文中执行
        //实现合约并没有真的被初始化
        (bool success,) = _logic.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success, "Call failed");
    }
    //逻辑合约调用代理的初始化函数 initialize()

    // 委托当前调用到实现合约
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            //将调用数据(calldata)复制到内存中，以便传递给实现合约
            //destOffset: 内存的目标位置 = 0
            //offset: calldata 的起始位置 = 0
            //length: 要复制的字节数 = calldatasize()
            calldatacopy(0, 0, calldatasize())
            //为什么要复制？
            //因为 delegatecall 需要从内存读取参数，不能直接读取 calldata。
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            //calldata 从内存位置0开始,长度为calldatasize()
            //实现合约执行完后，将返回数据复制到内存中
            //为什么要复制？
            //因为我们需要把 implementation 的返回值转发给原始调用者。
            returndatacopy(0, 0, returndatasize())
            switch result
            //result = 0: 调用失败 (revert) ✗
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // Fallback function that delegates calls to the address returned by `_implementation()`.
    // Will run if no other function in the contract matches the call data
    fallback() external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    // Returns an `AddressSlot` with member `value` located at `slot`.
    function _getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r_slot := slot
        }
    }
}

contract Engine is Initializable {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public upgrader;
    uint256 public horsePower;

    struct AddressSlot {
        address value;
    }
//Engine 合约本身从未被初始化！导致 任何人都可以初始化 Engine
    function initialize() external initializer {
        horsePower = 1000;
        upgrader = msg.sender;
    }

    // Upgrade the implementation of the proxy to `newImplementation`
    // subsequently execute the function call
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable {
        _authorizeUpgrade();
        _upgradeToAndCall(newImplementation, data);
    }

    // Restrict to upgrader role
    function _authorizeUpgrade() internal view {
        require(msg.sender == upgrader, "Can't upgrade");
    }

    // Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
    function _upgradeToAndCall(address newImplementation, bytes memory data) internal {
        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0) {
            (bool success,) = newImplementation.delegatecall(data);
            require(success, "Call failed");
        }
    }

    // Stores a new address in the EIP1967 implementation slot.
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");

        AddressSlot storage r;
        assembly {
            r_slot := _IMPLEMENTATION_SLOT
        }
        r.value = newImplementation;
    }
}
