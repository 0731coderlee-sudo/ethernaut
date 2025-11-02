import { createWalletClient, createPublicClient, http } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains';
import { getApprovalBasedPaymasterInput } from 'viem/zksync';

// ABI - 直接从你的 JSON 文件复制
const abi = [
    {
        "type": "function",
        "name": "authenticate",
        "inputs": [{ "name": "passkey", "type": "string" }],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "getCleared",
        "inputs": [],
        "outputs": [{ "name": "", "type": "bool" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "info",
        "inputs": [],
        "outputs": [{ "name": "", "type": "string" }],
        "stateMutability": "pure"
    },
    {
        "type": "function",
        "name": "info1",
        "inputs": [],
        "outputs": [{ "name": "", "type": "string" }],
        "stateMutability": "pure"
    },
    {
        "type": "function",
        "name": "info2",
        "inputs": [{ "name": "param", "type": "string" }],
        "outputs": [{ "name": "", "type": "string" }],
        "stateMutability": "pure"
    },
    {
        "type": "function",
        "name": "info42",
        "inputs": [],
        "outputs": [{ "name": "", "type": "string" }],
        "stateMutability": "pure"
    },
    {
        "type": "function",
        "name": "infoNum",
        "inputs": [],
        "outputs": [{ "name": "", "type": "uint8" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "method7123949",
        "inputs": [],
        "outputs": [{ "name": "", "type": "string" }],
        "stateMutability": "pure"
    },
    {
        "type": "function",
        "name": "password",
        "inputs": [],
        "outputs": [{ "name": "", "type": "string" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "theMethodName",
        "inputs": [],
        "outputs": [{ "name": "", "type": "string" }],
        "stateMutability": "view"
    }
];

// 从环境变量读取配置
const RPC_URL = process.env.sepolia_rpc;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.HELLO_ETHERNAUT_ADDRESS;

async function main() {
    //get_password
    const client = createPublicClient({
        chain: sepolia,
        transport: http(RPC_URL),
    });
    const password = await client.readContract({
        address: CONTRACT_ADDRESS,
        abi,
        functionName: 'password',
    });
    console.log(password);
    //verify
    const walletClient = createWalletClient({
        account: privateKeyToAccount(PRIVATE_KEY),
        chain: sepolia,
        transport: http(RPC_URL),
    });
    const hash = await walletClient.writeContract({
        address: CONTRACT_ADDRESS,
        abi,
        functionName: 'authenticate',
        args: [password],
    });
    console.log(`Transaction hash: ${hash}`);
    //check
    await client.waitForTransactionReceipt({ hash });
    console.log("✅ Confirmed");
    
}

main().catch(console.error);
