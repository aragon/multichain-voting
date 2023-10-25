// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;

import { console2 } from "forge-std/console2.sol";

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { DAO } from "@aragon/osx/core/dao/DAO.sol";
import { DAOMock } from "@aragon/osx/test/dao/DAOMock.sol";
import { IPluginSetup } from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import { DaoUnauthorized } from "@aragon/osx/core/utils/auth.sol";
import { PluginRepo } from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";

import { AragonE2E } from "./base/AragonE2E.sol";

import { L1TokenVotingSetup } from "../src/L1TokenVotingSetup.sol";
import { L1TokenVoting } from "../src/L1TokenVoting.sol";
import {GovernanceERC20} from "@aragon/osx/token/ERC20/governance/GovernanceERC20.sol";
import {GovernanceWrappedERC20} from "@aragon/osx/token/ERC20/governance/GovernanceWrappedERC20.sol";

contract SimpleStorageE2E is AragonE2E {
    DAO internal dao;
    L1TokenVoting internal plugin;
    PluginRepo internal repo;
    L1TokenVotingSetup internal setup;
    uint256 internal constant NUMBER = 420;
    address internal unauthorised = account("unauthorised");
    GovernanceERC20 governanceERC20Base;
    GovernanceWrappedERC20 governanceWrappedERC20Base;

    function setUp() public virtual override {
        super.setUp();
        address dead = address(0xdead);
        address bob = address(0xb0b);

        address[] memory holders = new address[](1);
        holders[0] = bob;
        uint256[] memory holdersAmount = new uint256[](1);
        holdersAmount[0] = 10 ether;
        governanceERC20Base = new GovernanceERC20(DAO(payable(dead)), "Dead", "DED", GovernanceERC20.MintSettings(holders, holdersAmount));
        governanceWrappedERC20Base = new GovernanceWrappedERC20(IERC20Upgradeable(address(governanceERC20Base)), "Dead", "DED");

        setup = new L1TokenVotingSetup(governanceERC20Base, governanceWrappedERC20Base);
        address _plugin;

        (dao, repo, _plugin) = deployRepoAndDao("L1TokenVoting4202934800", address(setup), abi.encode(NUMBER));

        plugin = L1TokenVoting(_plugin);
    }

    function test_e2e() public {
        // test repo
        PluginRepo.Version memory version = repo.getLatestVersion(repo.latestRelease());
        assertEq(version.pluginSetup, address(setup));
        assertEq(version.buildMetadata, NON_EMPTY_BYTES);

        // test dao
        assertEq(keccak256(bytes(dao.daoURI())), keccak256(bytes("https://mockDaoURL.com")));

        // test plugin init correctly
        // assertEq(plugin.number(), 420);

        // test dao store number
        vm.prank(address(dao));
        // plugin.storeNumber(69);

        // test unauthorised cannot store number
        vm.prank(unauthorised);
        vm.expectRevert(
            abi.encodeWithSelector(DaoUnauthorized.selector, dao, plugin, unauthorised, keccak256("STORE_PERMISSION"))
        );
        // plugin.storeNumber(69);
    }
}
