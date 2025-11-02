  执行步骤

  1. 部署攻击合约

  forge create src/08-Force/AttackForce.sol:AttackForce \
    --rpc-url $sepolia_rpc \
    --private-key $PRIVATE_KEY \
    --constructor-args $Force_ADDRESS

  2. 保存合约地址

  export AttackForce_ADDRESS=0x你的合约地址

  3. 运行攻击脚本

  node script/Force.js

  工作流程

  1. AttackForce 合约部署 ✓
                  ↓
  2. 发送 0.001 ETH 到 AttackForce
                  ↓
  3. 调用 attack() 函数
                  ↓
  4. selfdestruct(Force地址)
                  ↓
  5. EVM 直接转移余额，绕过 receive/fallback
                  ↓
  6. Force 合约被强制接收 ETH ✓

  关键点

  - 可读性更好：先部署，再调用，逻辑清晰
  - 可复用：可以多次向 AttackForce 发送 ETH，多次攻击（虽然第一次就会自毁）
  - 易于调试：可以分步验证每个环节

  这种方式比在构造函数里直接 selfdestruct 更灵活，也更容易理解！