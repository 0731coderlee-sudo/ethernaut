# 01 - Hello Ethernaut (Level 0)
```
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

```