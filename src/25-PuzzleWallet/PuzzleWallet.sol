// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../helpers/UpgradeableProxy-08.sol";

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData)
        UpgradeableProxy(_implementation, _initData)
    {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}
/**
// 在 PuzzleProxy 中调用
function proposeNewAdmin(address _newAdmin) external {
    pendingAdmin = _newAdmin;  // 修改 slot 0
}
// 实际上也修改了 PuzzleWallet 的 owner！  //代理合约和实现合约存储槽共享?
// 因为它们共享同一个存储槽 */
contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }
        // 执行转转eth给白名单地址
    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success,) = to.call{value: value}(data);
        require(success, "Execution failed");
    }

//data calldata格式的 函数调用的数组,每个元素都是一个完整的函数调用数据 包含了selector和calldata
/**
data = [
    abi.encodeWithSelector(deposit.selector),      // "调用 deposit()"
    abi.encodeWithSelector(execute.selector, ...),  // "调用 execute(...)"
]
 */
    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false; //防止在同个multicall中调用多次deposit
        for (uint256 i = 0; i < data.length; i++) {
            //遍历 data 数组中的每个函数调用。 复制到内存
            bytes memory _data = data[i];
            bytes4 selector; //函数选择器（前 4 字节）
            //解析calldata里面的函数选择器 
            assembly {
                selector := mload(add(_data, 32)) //数组长度占用了32字节,所以函数选择器在偏移32的位置
            }
            //匹配deposit函数
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}