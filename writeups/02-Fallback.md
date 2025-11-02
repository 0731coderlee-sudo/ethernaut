# 02 - Fallback
```
async function main() {
    // contribute 再触发receive 即可
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
```