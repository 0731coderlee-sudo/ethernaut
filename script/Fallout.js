import { createWalletClient, createPublicClient, http } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains';
import { getApprovalBasedPaymasterInput } from 'viem/zksync';

// ABI - 直接从你的 JSON 文件复制
const abi = [
    {
        "type": "function",
        "name": "Fal1out",
        "inputs": [],
        "outputs": [],
        "stateMutability": "payable",
        "payable": true,
        "signature": "0x6fab5ddf"
    },
    {
        "type": "function",
        "name": "allocate",
        "inputs": [],
        "outputs": [],
        "stateMutability": "payable",
        "payable": true,
        "signature": "0xabaa9916"
    },
    {
        "type": "function",
        "name": "allocatorBalance",
        "inputs": [
            {
                "name": "allocator",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view",
        "constant": true,
        "signature": "0xffd40b56"
    },
    {
        "type": "function",
        "name": "collectAllocations",
        "inputs": [],
        "outputs": [],
        "stateMutability": "nonpayable",
        "signature": "0x8aa96f38"
    },
    {
        "type": "function",
        "name": "owner",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address payable"
            }
        ],
        "stateMutability": "view",
        "constant": true,
        "signature": "0x8da5cb5b"
    },
    {
        "type": "function",
        "name": "sendAllocation",
        "inputs": [
            {
                "name": "allocator",
                "type": "address",
                "internalType": "address payable"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable",
        "signature": "0xa2dea26f"
    }
];

// 从环境变量读取配置
const RPC_URL = process.env.sepolia_rpc;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.Fallout_ADDRESS;

async function main() {
    // 调用 Fal1out 函数
    const client = createPublicClient({
        chain: sepolia,
        transport: http(RPC_URL),
    });

    const walletClient = createWalletClient({
        account: privateKeyToAccount(PRIVATE_KEY),
        chain: sepolia,
        transport: http(RPC_URL),
    });

    // 先检查当前 owner
    const owner = await client.readContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'owner',
    });
    console.log('Current owner:', owner);
    console.log('Your address:', walletClient.account.address);

    // 如果不是 owner,调用 Fal1out
    if (owner.toLowerCase() !== walletClient.account.address.toLowerCase()) {
        console.log('Calling Fal1out...');
        const tx = await walletClient.writeContract({
            address: CONTRACT_ADDRESS,
            abi: abi,
            functionName: 'Fal1out',
        });
        await client.waitForTransactionReceipt({ hash: tx });
        console.log('Fal1out tx hash:', tx);
    } else {
        console.log('Already owner!');
    }
}

main().catch(console.error);