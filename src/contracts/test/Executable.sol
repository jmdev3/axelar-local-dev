// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol';

contract Executable is AxelarExecutable {
    string public value;
    string public sourceChain;
    string public sourceAddress;
    IAxelarGasService public immutable gasReceiver;
    mapping(string => string) public siblings;

    constructor(address gateway_, address gasReceiver_) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
    }

    // Call this function on setup to tell this contract who it's sibling contracts are.
    function addSibling(string calldata chain_, string calldata address_) external {
        siblings[chain_] = address_;
    }

    // Call this function to update the value of this contract along with all its siblings'.
    function set(string memory chain, string calldata value_) external payable {
        value = value_;
        bytes memory payload = abi.encode(value_);
        if (msg.value > 0) {
            gasReceiver.payNativeGasForContractCall{ value: msg.value }(address(this), chain, siblings[chain], payload, msg.sender);
        }
        gateway.callContract(chain, siblings[chain], payload);
    }

    /* Handles calls created by setAndSend. Updates this contract's value
    and gives the token received to the destination specified at the source chain. */
    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        (value) = abi.decode(payload_, (string));
        sourceChain = sourceChain_;
        sourceAddress = sourceAddress_;
    }
}
