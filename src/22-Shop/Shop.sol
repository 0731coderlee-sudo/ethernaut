// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuyer {
  function price() external view returns (uint256);
}
//从外部获取定价 但是外部定价会根据商品状态变化 产生的价格操控
contract Shop {
  uint256 public price = 100;
  bool public isSold;

  function buy() public {
    IBuyer _buyer = IBuyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}