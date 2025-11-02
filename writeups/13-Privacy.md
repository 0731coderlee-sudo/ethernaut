# 13 Privacy
```
Solidity 存储打包的规则：
只有连续声明的变量才会尝试打包
只有总大小不超过32字节的变量才会打包到同一个槽
uint256 总是占用完整的32字节槽，不会与其他变量打包

bool public locked = true;              // 1 字节
uint256 public ID = block.timestamp;    // 32 字节 - 完整槽！
uint8 private flattening = 10;          // 1 字节
uint8 private denomination = 255;       // 1 字节
uint16 private awkwardness = ...;       // 2 字节
bytes32[3] private data;                // 3 × 32 字节
```

