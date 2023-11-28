// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {L2TokenVotingSetup} from "../src/L2TokenVotingSetup.sol";
import {L2TokenVoting} from "../src/L2TokenVoting.sol";
import {GovernanceERC20} from "@aragon/osx/token/ERC20/governance/GovernanceERC20.sol";
import {GovernanceWrappedERC20} from "@aragon/osx/token/ERC20/governance/GovernanceWrappedERC20.sol";

contract L2TokenVotingDeploymentScript is Script {
    function run() public returns (L2TokenVotingSetup l2Setup) {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address governanceERC20Mumbai = vm.envAddress("MUMBAI_GOVERNANCE_ERC20_BASE");
        address governanceWrapperERC20Mumbai = vm.envAddress(
            "MUMBAI_GOVERNANCE_WRAPPER_ERC20_BASE"
        );

        l2Setup = new L2TokenVotingSetup(
            GovernanceERC20(governanceERC20Mumbai),
            GovernanceWrappedERC20(governanceWrapperERC20Mumbai)
        );
        vm.stopBroadcast();
    }
}
