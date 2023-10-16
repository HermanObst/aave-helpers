// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';

interface ZkEVMBridge {
  function claimMessage(
    bytes32[32] calldata smtProof,
    uint32 index,
    bytes32 mainnetExitRoot,
    bytes32 rollupExitRoot,
    uint32 originNetwork,
    address originAddress,
    uint32 destinationNetwork,
    address destinationAddress,
    uint256 amount,
    bytes calldata metadata
  ) external;
}

contract ClaimZkEVMMessage is Script {
  address constant ZK_EVM_BRIDGE = 0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe;

  address constant DESTINATION = 0x889c0cc3283DB588A34E89Ad1E8F25B0fc827b4b;

  function getProof()
    internal
    returns (
      bytes32[32] memory smtProof,
      uint32 index,
      bytes32 mainnetExitRoot,
      bytes32 rollupExitRoot,
      uint32 originNetwork,
      address originAddress,
      uint32 destinationNetwork,
      address destinationAddress,
      uint256 amount,
      bytes memory metadata
    )
  {
    string[] memory inputs = new string[](3);
    inputs[0] = 'node';
    inputs[1] = 'fetch.js';
    inputs[2] = vm.toString(DESTINATION);
    bytes memory response = vm.ffi(inputs);
    return
      abi.decode(
        response,
        (bytes32[32], uint32, bytes32, bytes32, uint32, address, uint32, address, uint256, bytes)
      );
  }

  function run() external {
    (
      bytes32[32] memory smtProof,
      uint32 index,
      bytes32 mainnetExitRoot,
      bytes32 rollupExitRoot,
      uint32 originNetwork,
      address originAddress,
      uint32 destinationNetwork,
      address destinationAddress,
      uint256 amount,
      bytes memory metadata
    ) = getProof();
    vm.startBroadcast();
    ZkEVMBridge(ZK_EVM_BRIDGE).claimMessage(
      smtProof,
      index,
      mainnetExitRoot,
      rollupExitRoot,
      originNetwork,
      originAddress,
      destinationNetwork,
      destinationAddress,
      amount,
      metadata
    );
  }
}
