# Ethernaut CTF Solutions

Ethernaut关卡解决方案，使用Foundry框架实现完整的POC和详细的writeup文档。

## 项目结构

```
ethernaut/
├── src/                          # 源合约目录
│   ├── 01-Fallout/              # 关卡1：构造函数名称错误
│   │   └── Fallout.sol
│   ├── 02-Fallback/             # 关卡2：receive函数漏洞
│   │   └── Fallback.sol
│   └── 03-HelloEthernaut/       # 关卡0：教程关卡
│       └── Instance.sol
│
├── test/                         # 测试文件目录
│   ├── 01-Fallout.t.sol         # Fallout POC测试
│   ├── 02-Fallback.t.sol        # Fallback POC测试
│   └── 03-HelloEthernaut.t.sol  # HelloEthernaut POC测试
│
├── writeups/                     # Writeup文档目录
│   ├── 01-Fallout.md
│   ├── 02-Fallback.md
│   └── 03-HelloEthernaut.md
│
├── lib/                          # 依赖库
│   ├── forge-std/               # Foundry标准库
│   └── openzeppelin-contracts/  # OpenZeppelin合约库
│
├── foundry.toml                  # Foundry配置文件
└── remappings.txt                # 导入映射配置
```

## 环境要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.6.0 和 ^0.8.0

## 安装

```bash
# 克隆项目
git clone <your-repo>
cd ethernaut

# 安装依赖（如果还没安装）
forge install

# 编译合约
forge build
```

## 运行测试

### 运行所有测试
```bash
forge test
```

### 运行特定关卡的测试
```bash
# Fallout关卡
forge test --match-contract FalloutTest -vvv

# Fallback关卡
forge test --match-contract FallbackTest -vvv

# HelloEthernaut关卡
forge test --match-contract HelloEthernautTest -vvv
```

### 运行特定测试函数
```bash
forge test --match-test testExploitConstructorTypo -vvvv
```

### 查看详细日志
```bash
forge test -vvvv
```

### 查看Gas报告
```bash
forge test --gas-report
```

## 关卡列表

### 01 - Fallout
- **漏洞类型**: 构造函数名称拼写错误
- **难度**: ⭐⭐
- **关键点**: \`Fal1out\`(数字1)不是\`Fallout\`(字母l)
- **测试**: \`forge test --match-contract FalloutTest -vvv\`
- **Writeup**: [01-Fallout.md](writeups/01-Fallout.md)

### 02 - Fallback
- **漏洞类型**: receive函数权限控制缺陷
- **难度**: ⭐⭐
- **关键点**: receive函数中的ownership变更条件太弱
- **测试**: \`forge test --match-contract FallbackTest -vvv\`
- **Writeup**: [02-Fallback.md](writeups/02-Fallback.md)

### 03 - Hello Ethernaut (Level 0)
- **类型**: 教程关卡
- **难度**: ⭐
- **关键点**: 学习合约交互和区块链透明性
- **测试**: \`forge test --match-contract HelloEthernautTest -vvv\`
- **Writeup**: [03-HelloEthernaut.md](writeups/03-HelloEthernaut.md)

## 测试结果

```
Ran 3 test suites: 14 tests passed, 0 failed

01-Fallout:       3 passed ✅
02-Fallback:      5 passed ✅
03-HelloEthernaut: 6 passed ✅
```

## 开发工具

### Foundry命令速查

```bash
# 编译
forge build

# 测试
forge test
forge test -vv          # 显示失败的测试
forge test -vvv         # 显示所有测试日志
forge test -vvvv        # 显示traces
forge test --gas-report # Gas报告

# 格式化
forge fmt

# 清理
forge clean
```

### 有用的测试选项

```bash
# 只运行匹配的测试
--match-test <PATTERN>      # 匹配测试函数名
--match-contract <PATTERN>  # 匹配合约名
--match-path <PATH>         # 匹配文件路径

# 显示级别
-v      # 基本输出
-vv     # 显示失败的测试
-vvv    # 显示所有测试日志
-vvvv   # 显示trace和setup
-vvvvv  # 显示详细trace
```

## Writeup文档

每个writeup包含：
- 关卡信息和目标
- 详细的漏洞分析
- 完整的攻击步骤
- 代码示例
- 安全启示和防御建议
- 相关资源链接

## 学习资源

- [Ethernaut官方网站](https://ethernaut.openzeppelin.com/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity文档](https://docs.soliditylang.org/)
- [OpenZeppelin文档](https://docs.openzeppelin.com/)
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)

## 安全免责声明

本项目仅用于教育和安全研究目的。所有POC代码仅应在测试环境中使用。切勿在生产环境或未经授权的系统上使用这些技术。

## 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## License

MIT License
