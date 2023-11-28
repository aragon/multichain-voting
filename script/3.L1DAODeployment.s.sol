// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {L1TokenVotingSetup} from "../src/L1TokenVotingSetup.sol";
import {L2TokenVotingSetup} from "../src/L2TokenVotingSetup.sol";
import {L2TokenVoting} from "../src/L2TokenVoting.sol";
import {L1TokenVoting} from "../src/L1TokenVoting.sol";
import {L1MajorityVotingBase} from "../src/L1MajorityVotingBase.sol";
import {GovernanceERC20} from "@aragon/osx/token/ERC20/governance/GovernanceERC20.sol";
import {GovernanceWrappedERC20} from "@aragon/osx/token/ERC20/governance/GovernanceWrappedERC20.sol";

import {DAOFactory} from "@aragon/osx/framework/dao/DAOFactory.sol";
import {hashHelpers, PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";

contract DaoDeploymentScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address l1TokenVotingSetupRef = vm.envAddress("GOERLI_TOKEN_VOTING_SETUP_REPO");
        address holder = vm.envAddress("GOERLI_TOKEN_HOLDER");

        L1MajorityVotingBase.VotingSettings memory votingSettings = L1MajorityVotingBase
            .VotingSettings(uint32(0), uint32(1), 60 minutes, uint256(0));

        L1TokenVotingSetup.TokenSettings memory tokenSettings = L1TokenVotingSetup.TokenSettings(
            address(0),
            "multichainvoting",
            "MCV"
        );
        address[] memory holders = new address[](1);
        holders[0] = holder;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10 ether;

        GovernanceERC20.MintSettings memory mintSettings = GovernanceERC20.MintSettings(
            holders,
            amounts
        );

        bytes memory pluginSettingsData = abi.encode(votingSettings, tokenSettings, mintSettings);

        DAOFactory daoFactory = DAOFactory(vm.envAddress("GOERLI_DAO_FACTORY"));
        DAOFactory.DAOSettings memory daoSettings = DAOFactory.DAOSettings(
            address(0),
            "",
            "crosschaindao",
            ""
        );
        PluginRepo.Tag memory tag = PluginRepo.Tag(1, 1);
        DAOFactory.PluginSettings[] memory pluginSettings = new DAOFactory.PluginSettings[](1);
        pluginSettings[0] = DAOFactory.PluginSettings(
            PluginSetupRef(tag, PluginRepo(l1TokenVotingSetupRef)),
            pluginSettingsData
        );

        daoFactory.createDao(daoSettings, pluginSettings);
        vm.stopBroadcast();
    }
}
