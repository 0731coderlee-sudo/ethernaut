import { createWalletClient, createPublicClient, http } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains';
import { getApprovalBasedPaymasterInput } from 'viem/zksync';

// ABI - 直接从你的 JSON 文件复制
const abi = [
    {
        "type": "constructor",
        "inputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "receive",
        "stateMutability": "payable",
        "payable": true
    },
    {
        "type": "function",
        "name": "contribute",
        "inputs": [],
        "outputs": [],
        "stateMutability": "payable",
        "payable": true,
        "signature": "0xd7bb99ba"
    },
    {
        "type": "function",
        "name": "contributions",
        "inputs": [
            {
                "name": "",
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
        "signature": "0x42e94c90"
    },
    {
        "type": "function",
        "name": "getContribution",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view",
        "constant": true,
        "signature": "0xf10fdf5c"
    },
    {
        "type": "function",
        "name": "owner",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view",
        "constant": true,
        "signature": "0x8da5cb5b"
    },
    {
        "type": "function",
        "name": "withdraw",
        "inputs": [],
        "outputs": [],
        "stateMutability": "nonpayable",
        "signature": "0x3ccfd60b"
    }
];
// 从环境变量读取配置
const RPC_URL = process.env.sepolia_rpc;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.Fallback_ADDRESS;


async function main() {
    // contribute 触发receive 即可
    const client = createPublicClient({
        chain: sepolia,
        transport: http(RPC_URL),
    });

    const walletClient = createWalletClient({
        account: privateKeyToAccount(PRIVATE_KEY),
        chain: sepolia,
        transport: http(RPC_URL),
    });
    // call contribute
    const tx = await walletClient.writeContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'contribute',
        value: 1n // 1 wei
    });
    await client.waitForTransactionReceipt({ hash: tx });
    console.log('contribute tx hash:', tx);
    
    //check contribution
    const getContribution = await client.readContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'contributions',
        args: [privateKeyToAccount(PRIVATE_KEY).address],
    });
    console.log('Your contribution:', getContribution, 'wei');

    //revoke receive() by sending 1 wei
    const tx2 = await walletClient.sendTransaction({
        to: CONTRACT_ADDRESS,
        value: 1n // 1 wei
    });
    await client.waitForTransactionReceipt({ hash: tx2 });
    console.log('revoke receive tx hash:', tx2);

    // withdraw
    const tx3 = await walletClient.writeContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'withdraw',
    });
    await client.waitForTransactionReceipt({ hash: tx3 });
    console.log('withdraw tx hash:', tx3);

    //check balance
    const balance = await client.getBalance({
        address: CONTRACT_ADDRESS,
    });
    console.log('Contract balance:', balance, 'wei');

    // is owner?
    const owner = await client.readContract({
        address: CONTRACT_ADDRESS,
        abi: abi,
        functionName: 'owner',
    });
    console.log('owner:', owner);
}

main().catch(console.error);


