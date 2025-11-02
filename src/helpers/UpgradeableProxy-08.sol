// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`.
     */
    fallback() external payable virtual {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`.
     */
    receive() external payable virtual {
        _delegate(_implementation());
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual returns (address);
}

/**
 * @dev Upgradeable proxy pattern
 */
contract UpgradeableProxy is Proxy {
    // Storage slot with the address of the current implementation.
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);

    constructor(address _logic, bytes memory _data) payable {
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success,) = _logic.delegatecall(_data);
            require(success, "Initialization failed");
        }
    }

    function _implementation() internal view override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
    }

    function _setImplementation(address newImplementation) private {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
        emit Upgraded(newImplementation);
    }
}
