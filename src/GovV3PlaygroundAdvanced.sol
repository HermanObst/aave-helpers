// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {GovV3Helpers, IPayloadsControllerCore, PayloadsControllerUtils} from './GovV3Helpers.sol';

contract LetMeJustHaveSome {
  string public name = 'some';
}

contract LetMeJustHaveAnother {
  string public name = 'another';
}

abstract contract WithPayloads {
  struct ActionsPerChain {
    string chainName;
    bytes[] actionCode;
  }

  function getActions() public view virtual returns (ActionsPerChain[] memory);
}

abstract contract WithPayloadsSimple is WithPayloads {
  function getActionsOneChain() public view virtual returns (ActionsPerChain memory);

  function getActions() public view override returns (ActionsPerChain[] memory) {
    ActionsPerChain[] memory actions = new ActionsPerChain[](1);
    actions[0] = getActionsOneChain();
    return actions;
  }
}

abstract contract DeployPayloads is WithPayloads, Script {
  function run() external {
    ActionsPerChain[] memory actionsPerChain = getActions();

    for (uint256 i = 0; i < actionsPerChain.length; i++) {
      ActionsPerChain memory rawActions = actionsPerChain[i];
      require(rawActions.actionCode.length != 0, 'should be at least one payload action per chain');

      vm.rpcUrl(rawActions.chainName);
      vm.startBroadcast();

      // compose actions
      IPayloadsControllerCore.ExecutionAction[]
        memory composedActions = new IPayloadsControllerCore.ExecutionAction[](
          rawActions.actionCode.length
        );
      // deploy payloads
      for (uint256 j = 0; j < rawActions.actionCode.length; j++) {
        composedActions[j] = GovV3Helpers.buildAction(
          GovV3Helpers.deployDeterministic(rawActions.actionCode[j])
        );
      }

      // register actions at payloadsController
      GovV3Helpers.createPayload(composedActions);
      vm.stopBroadcast();
    }
  }
}

abstract contract CreateProposal is WithPayloads, Script {
  string internal _ipfsFilePath;

  constructor(string memory ipfsFilePath) {
    _ipfsFilePath = ipfsFilePath;
  }

  function run() external {
    ActionsPerChain[] memory actionsPerChain = getActions();

    // create payloads
    PayloadsControllerUtils.Payload[] memory payloadsPinned = new PayloadsControllerUtils.Payload[](
      actionsPerChain.length
    );

    for (uint256 i = 0; i < actionsPerChain.length; i++) {
      ActionsPerChain memory rawActions = actionsPerChain[i];
      vm.rpcUrl(rawActions.chainName);

      IPayloadsControllerCore.ExecutionAction[]
        memory actions = new IPayloadsControllerCore.ExecutionAction[](
          rawActions.actionCode.length
        );

      for (uint256 j = 0; j < rawActions.actionCode.length; j++) {
        actions[j] = GovV3Helpers.buildAction(rawActions.actionCode[j]);
      }
      payloadsPinned[i] = GovV3Helpers._buildPayload(vm, block.chainid, actions);
    }

    // create proposal
    vm.rpcUrl('ethereum');
    vm.startBroadcast();
    GovV3Helpers.createProposal(vm, payloadsPinned, GovV3Helpers.ipfsHashFile(vm, _ipfsFilePath));
    vm.stopBroadcast();
  }
}

abstract contract MySimplePayloads is WithPayloadsSimple {
  function getActionsOneChain() public pure override returns (ActionsPerChain memory) {
    ActionsPerChain memory payload;

    payload.chainName = 'ethereum';
    payload.actionCode = new bytes[](2);
    payload.actionCode[0] = type(LetMeJustHaveSome).creationCode;
    payload.actionCode[1] = type(LetMeJustHaveAnother).creationCode;

    return payload;
  }
}

contract DeploymentSimple is MySimplePayloads, DeployPayloads {}

contract ProposalCreationSimple is
  MySimplePayloads,
  CreateProposal(
    'src/20240121_Multi_UpdateStETHAndWETHRiskParamsOnAaveV3EthereumOptimismAndArbitrum/UpdateStETHAndWETHRiskParamsOnAaveV3EthereumOptimismAndArbitrum.md'
  )
{}
