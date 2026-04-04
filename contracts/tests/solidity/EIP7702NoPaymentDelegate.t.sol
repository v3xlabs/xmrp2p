// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract EIP7702NoPaymentDelegate {
    /// Receive function
    receive() external payable {
        revert();
    }

    /// Fallback function
    fallback() external payable {
        revert();
    }
}
