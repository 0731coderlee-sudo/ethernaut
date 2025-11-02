import { createWalletClient, createPublicClient, http } from "viem";
import { sepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

const TOKEN_ADDRESS = process.env.Token_ADDRESS
const RPC_URL = process.env.sepolia_rpc
const PRIVATE_KEY = process.env.PRIVATE_KEY

const abi = [
    {
        "type": "constructor",
        "inputs": [
            {
                "name": "_initialSupply",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "balanceOf",
        "inputs": [
            {
                "name": "_owner",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "balance",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view",
        "constant": true,
        "signature": "0x70a08231"
    },
    {
        "type": "function",
        "name": "totalSupply",
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
        "signature": "0x18160ddd"
    },
    {
        "type": "function",
        "name": "transfer",
        "inputs": [
            {
                "name": "_to",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_value",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "signature": "0xa9059cbb"
    }
]

async function main() {
    const client = createPublicClient({
        chain: sepolia,
        transport: http(RPC_URL),
    })

    const account = privateKeyToAccount(PRIVATE_KEY);
    const walletClient = createWalletClient({
        account,
        chain: sepolia,
        transport: http(RPC_URL),
    })

    await client.readContract({
        address: TOKEN_ADDRESS,
        abi: abi,
        functionName: 'totalSupply',
    }).then((res) => {
        console.log('Total Supply:', res);
    });
    
    await client.readContract({
        address: TOKEN_ADDRESS,
        abi: abi,
        functionName: 'balanceOf',
        args: [account.address],
    }).then((res) => {
        console.log('Balance:', res);
    });

    // transfer 21 token 
    const tx = await walletClient.writeContract({
        address: TOKEN_ADDRESS,
        abi: abi,
        functionName: 'transfer',
        args: ['0x000000000000000000000000000000000000dEaD', 21n * 10n ** 18n],
    });
    await client.waitForTransactionReceipt({ hash: tx });
    console.log('Transfer tx hash:', tx);

    //check balance
    await client.readContract({
        address: TOKEN_ADDRESS,
        abi: abi,
        functionName: 'balanceOf',
        args: [account.address],
    }).then((res) => {
        console.log('Balance:', res);
    });

}

main().catch(console.error);