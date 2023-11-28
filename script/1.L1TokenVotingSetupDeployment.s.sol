// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {L1TokenVotingSetup} from "../src/L1TokenVotingSetup.sol";
import {L1TokenVoting} from "../src/L1TokenVoting.sol";
import {GovernanceERC20} from "@aragon/osx/token/ERC20/governance/GovernanceERC20.sol";
import {GovernanceWrappedERC20} from "@aragon/osx/token/ERC20/governance/GovernanceWrappedERC20.sol";

contract SetupDeploymentScript is Script {
    function run() public returns (L1TokenVotingSetup l1Setup) {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address governanceERC20 = vm.envAddress("GOERLI_GOVERNANCE_ERC20_BASE");
        address governanceWrapperERC20 = vm.envAddress("GOERLI_GOVERNANCE_WRAPPER_ERC20_BASE");

        l1Setup = new L1TokenVotingSetup(
            GovernanceERC20(governanceERC20),
            GovernanceWrappedERC20(governanceWrapperERC20)
        );

        vm.stopBroadcast();
    }
}
