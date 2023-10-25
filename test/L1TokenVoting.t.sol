// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;

import { console2 } from "forge-std/console2.sol";

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { DAO } from "@aragon/osx/core/dao/DAO.sol";
import { DAOMock } from "@aragon/osx/test/dao/DAOMock.sol";
import { IPluginSetup } from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import { DaoUnauthorized } from "@aragon/osx/core/utils/auth.sol";

import { AragonTest } from "./base/AragonTest.sol";

import { L1TokenVotingSetup } from "../src/L1TokenVotingSetup.sol";
import { L1MajorityVotingBase } from "../src/L1MajorityVotingBase.sol";
import { L1TokenVoting } from "../src/L1TokenVoting.sol";

import {GovernanceERC20} from "@aragon/osx/token/ERC20/governance/GovernanceERC20.sol";
import {GovernanceWrappedERC20} from "@aragon/osx/token/ERC20/governance/GovernanceWrappedERC20.sol";

abstract contract L1TokenVotingTest is AragonTest {
    DAO internal dao;
    L1TokenVoting internal plugin;
    L1TokenVotingSetup internal setup;
    uint256 internal constant NUMBER = 420;
    GovernanceERC20 governanceERC20Base;
    GovernanceWrappedERC20 governanceWrappedERC20Base;

    function setUp() public virtual {
        address dead = address(0xdead);
        address bob = address(0xb0b);

        address[] memory holders = new address[](1);
        holders[0] = bob;
        uint256[] memory holdersAmount = new uint256[](1);
        holdersAmount[0] = 10 ether;
        governanceERC20Base = new GovernanceERC20(DAO(payable(dead)), "Dead", "DED", GovernanceERC20.MintSettings(holders, holdersAmount));
        governanceWrappedERC20Base = new GovernanceWrappedERC20(IERC20Upgradeable(address(governanceERC20Base)), "Dead", "DED");

        setup = new L1TokenVotingSetup(governanceERC20Base, governanceWrappedERC20Base);
        bytes memory setupData = abi.encode(NUMBER);

        (DAO _dao, address _plugin) = createMockDaoWithPlugin(setup, setupData);

        dao = _dao;
        plugin = L1TokenVoting(_plugin);
    }
}

contract L1TokenVotingInitializeTest is L1TokenVotingTest {
    function setUp() public override {
        super.setUp();
    }

    function test_initialize() public {
        assertEq(address(plugin.dao()), address(dao));
        // assertEq(plugin.number(), NUMBER);
    }

    function test_reverts_if_reinitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        L1MajorityVotingBase.VotingSettings memory votingSettings = L1MajorityVotingBase.VotingSettings(
            L1MajorityVotingBase.VotingMode.VoteReplacement,
            uint32(0),
            uint32(1),
            uint64(1),
            uint256(0)
        );
        L1MajorityVotingBase.BridgeSettings memory bridgeSettings = L1MajorityVotingBase.BridgeSettings(1, address(0), DAO(payable(address(0))), address(0));
        plugin.initialize(dao, votingSettings, governanceERC20Base, bridgeSettings);
    }
}

contract SimpleStorageStoreNumberTest is L1TokenVotingTest {
    function setUp() public override {
        super.setUp();
    }

    function test_store_number() public {
        vm.prank(address(dao));
        // plugin.storeNumber(69);
        // assertEq(plugin.number(), 69);
    }

    function test_reverts_if_not_auth() public {
        // error DaoUnauthorized({
        //     dao: address(_dao),
        //     where: _where,
        //     who: _who,
        //     permissionId: _permissionId
        // });
        vm.expectRevert(
            abi.encodeWithSelector(DaoUnauthorized.selector, dao, plugin, address(this), keccak256("STORE_PERMISSION"))
        );

        // plugin.storeNumber(69);
    }
}
