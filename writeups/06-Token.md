# 06-Token
```
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
```