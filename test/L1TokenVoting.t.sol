// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;

import {console2} from "forge-std/console2.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {DAOMock} from "@aragon/osx/test/dao/DAOMock.sol";
import {IPluginSetup} from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import {DaoUnauthorized} from "@aragon/osx/core/utils/auth.sol";
import {IMajorityVoting} from "@aragon/osx/plugins/governance/majority-voting/IMajorityVoting.sol";

import {AragonTest} from "./base/AragonTest.sol";
import {IPluginSetup, PluginSetup} from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";

import {ILayerZeroSender} from "../src/interfaces/ILayerZeroSender.sol";

import {L1TokenVotingSetup} from "../src/L1TokenVotingSetup.sol";
import {L1MajorityVotingBase} from "../src/L1MajorityVotingBase.sol";
import {L1TokenVoting} from "../src/L1TokenVoting.sol";

import {L2TokenVotingSetup} from "../src/L2TokenVotingSetup.sol";
import {L2MajorityVotingBase} from "../src/L2MajorityVotingBase.sol";
import {L2TokenVoting} from "../src/L2TokenVoting.sol";
import {IL2MajorityVoting} from "../src/interfaces/IL2MajorityVoting.sol";
import {NonblockingLzDAOProxy} from "../src/NonblockingLzDAOProxy.sol";

import {GovernanceERC20} from "@aragon/osx/token/ERC20/governance/GovernanceERC20.sol";
import {GovernanceWrappedERC20} from "@aragon/osx/token/ERC20/governance/GovernanceWrappedERC20.sol";

import {LZEndpointMock} from "./mocks/LayerZeroBridgeMock.sol";

abstract contract L1TokenVotingTest is AragonTest {
    DAO internal dao;
    L1TokenVoting internal plugin;
    L1TokenVotingSetup internal setup;
    GovernanceERC20 l1governanceERC20Base;
    GovernanceERC20 l2governanceERC20Base;
    GovernanceWrappedERC20 governanceWrappedERC20Base;
    LZEndpointMock l1Bridge;
    LZEndpointMock l2Bridge;
    NonblockingLzDAOProxy l2daoProxy;

    DAO internal l2dao;
    L2TokenVoting internal l2plugin;
    L2TokenVotingSetup internal l2setup;
    address bob = address(0xb0b);
    address dad = address(0xdad);
    address dead = address(0xdead);

    function setUpL1() public virtual {
        vm.deal(bob, 10 ether);
        vm.deal(dad, 10 ether);
        vm.roll(1);
        address[] memory holders = new address[](1);
        holders[0] = bob;
        uint256[] memory holdersAmount = new uint256[](1);
        holdersAmount[0] = 10 ether;
        l1governanceERC20Base = new GovernanceERC20(
            DAO(payable(dead)),
            "Dead",
            "DED",
            GovernanceERC20.MintSettings(holders, holdersAmount)
        );
        governanceWrappedERC20Base = new GovernanceWrappedERC20(
            IERC20Upgradeable(address(l1governanceERC20Base)),
            "Dead",
            "DED"
        );

        L1MajorityVotingBase.VotingSettings memory votingSettings = L1MajorityVotingBase
            .VotingSettings(
                L1MajorityVotingBase.VotingMode.EarlyExecution,
                uint32(0),
                uint32(1),
                61 minutes,
                uint256(0)
            );

        L1TokenVotingSetup.TokenSettings memory tokenSettings = L1TokenVotingSetup.TokenSettings(
            address(l1governanceERC20Base),
            "",
            ""
        );
        address[] memory receivers = new address[](1);
        receivers[0] = bob;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10 ether;
        GovernanceERC20.MintSettings memory mintSettings = GovernanceERC20.MintSettings(
            receivers,
            amounts
        );

        setup = new L1TokenVotingSetup(l1governanceERC20Base, governanceWrappedERC20Base);
        bytes memory setupData = abi.encode(votingSettings, tokenSettings, mintSettings);

        (
            DAO _dao,
            address _plugin,
            PluginSetup.PreparedSetupData memory _preparedSetupData
        ) = createMockDaoWithPlugin(setup, setupData);

        dao = _dao;
        plugin = L1TokenVoting(_plugin);
        l1Bridge = new LZEndpointMock(uint16(1));
        l2Bridge = new LZEndpointMock(uint16(5));
        l2Bridge.setDestLzEndpoint(address(plugin), address(l1Bridge));
        assertEq(
            address(plugin.getVotingToken()),
            address(l1governanceERC20Base),
            "Token is not set properly"
        );
    }

    function setUpL2() public virtual {
        address[] memory holders = new address[](1);
        holders[0] = dad;
        uint256[] memory holdersAmount = new uint256[](1);
        holdersAmount[0] = 10 ether;
        l2governanceERC20Base = new GovernanceERC20(
            DAO(payable(dead)),
            "Dead",
            "DED",
            GovernanceERC20.MintSettings(holders, holdersAmount)
        );
        governanceWrappedERC20Base = new GovernanceWrappedERC20(
            IERC20Upgradeable(address(l2governanceERC20Base)),
            "Dead",
            "DED"
        );

        L2MajorityVotingBase.VotingSettings memory votingSettings = L2MajorityVotingBase
            .VotingSettings(
                L2MajorityVotingBase.VotingMode.EarlyExecution,
                uint32(0),
                uint32(1),
                61 minutes,
                uint256(0)
            );

        L2TokenVotingSetup.TokenSettings memory tokenSettings = L2TokenVotingSetup.TokenSettings(
            address(l2governanceERC20Base),
            "",
            ""
        );
        address[] memory receivers = new address[](1);
        receivers[0] = dad;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10 ether;
        GovernanceERC20.MintSettings memory mintSettings = GovernanceERC20.MintSettings(
            receivers,
            amounts
        );

        L2MajorityVotingBase.BridgeDAOSettings memory bridgeDAOSettings = L2MajorityVotingBase
            .BridgeDAOSettings(address(dao), address(plugin), l2Bridge);

        l2setup = new L2TokenVotingSetup(l2governanceERC20Base, governanceWrappedERC20Base);
        bytes memory setupData = abi.encode(
            votingSettings,
            tokenSettings,
            mintSettings,
            bridgeDAOSettings
        );

        (
            DAO _dao,
            address _l2plugin,
            PluginSetup.PreparedSetupData memory preparedSetupData
        ) = createMockDaoWithPlugin(l2setup, setupData);

        l2dao = _dao;
        l2plugin = L2TokenVoting(_l2plugin);
        l2daoProxy = NonblockingLzDAOProxy(preparedSetupData.helpers[1]);
        l1Bridge.setDestLzEndpoint(address(l2plugin), address(l2Bridge));
    }

    function setUpPostInstallation() public virtual {
        vm.startPrank(bob);
        l1governanceERC20Base.delegate(bob);
        vm.warp(block.timestamp + 100);
        vm.roll(block.number + 2);
        bytes memory _metadata = abi.encodeWithSelector(
            L1TokenVoting.updateBridgeSettings.selector,
            uint16(5), // Or other chain really
            address(l1Bridge),
            address(l2dao),
            address(l2plugin)
        );
        IDAO.Action[] memory _actions = new IDAO.Action[](1);
        _actions[0] = IDAO.Action(address(plugin), 0, _metadata);
        uint256 _allowFailureMap = 0;
        uint64 _startDate = uint64(block.timestamp);
        uint64 _endDate = uint64(block.timestamp + 5000);
        L1MajorityVotingBase.VoteOption _voteOption = IMajorityVoting.VoteOption.Yes;
        bool _tryEarlyExecution = true;
        uint256 proposalId = plugin.createProposal{value: 0.5 ether}(
            _metadata,
            _actions,
            _allowFailureMap,
            _startDate,
            _endDate,
            _voteOption,
            _tryEarlyExecution
        );

        (
            bool open,
            bool executed,
            L1MajorityVotingBase.ProposalParameters memory params,
            L1MajorityVotingBase.Tally memory tally,
            IDAO.Action[] memory actions,
            uint256 allowFailureMap
        ) = plugin.getProposal(proposalId);

        (uint16 chainId, address _bridge, address _dao, address _childPlugin) = plugin
            .bridgeSettings();

        assertEq(_bridge, address(l1Bridge), "Bridge is not properly set");
        vm.stopPrank();
    }
}

contract L1TokenVotingInitializeTest is L1TokenVotingTest {
    function setUp() public {
        super.setUpL1();
        super.setUpL2();
        super.setUpPostInstallation();
    }

    function test_initialize() public {
        assertEq(address(plugin.dao()), address(dao));
        // assertEq(plugin.number(), NUMBER);
    }

    function test_reverts_if_reinitialized() public {
        L1MajorityVotingBase.VotingSettings memory votingSettings = L1MajorityVotingBase
            .VotingSettings(
                L1MajorityVotingBase.VotingMode.VoteReplacement,
                uint32(0),
                uint32(1),
                uint64(1),
                uint256(0)
            );
        vm.expectRevert("Initializable: contract is already initialized");
        plugin.initialize(dao, votingSettings, l1governanceERC20Base);
    }

    function test_FirstProposalBeingBridged() public {
        console2.log(address(dao));
        console2.log(address(plugin));
        console2.log(address(l2dao));
        console2.log(address(l2plugin));
        console2.log(address(l1Bridge));
        console2.log(address(l2Bridge));
        vm.startPrank(bob);
        vm.warp(block.timestamp + 100);
        vm.roll(block.number + 2);
        bytes memory _metadata = abi.encodeWithSelector(
            L1TokenVoting.updateBridgeSettings.selector,
            uint16(1), // Or other chain really
            address(l1Bridge),
            address(l2dao),
            address(l2plugin)
        );
        IDAO.Action[] memory _actions = new IDAO.Action[](0);
        uint256 _allowFailureMap = 0;
        uint64 _startDate = uint64(block.timestamp);
        uint64 _endDate = uint64(block.timestamp + 5000);

        L1MajorityVotingBase.VoteOption _voteOption = IMajorityVoting.VoteOption.Yes;
        bool _tryEarlyExecution = true;
        uint256 proposalId = plugin.createProposal{value: 0.5 ether}(
            _metadata,
            _actions,
            _allowFailureMap,
            _startDate,
            _endDate,
            _voteOption,
            _tryEarlyExecution
        );

        assertEq(proposalId, uint256(1), "ProposalId is not correct");
        vm.stopPrank();
        vm.startPrank(dad);
        l2plugin.vote(0, IL2MajorityVoting.VoteOption.Yes);
        l2plugin.execute{value: 0.5 ether}(0);
        vm.stopPrank();

        (
            bool open,
            uint256 parentProposalId,
            bool executed,
            L2MajorityVotingBase.ProposalParameters memory parameters,
            L2MajorityVotingBase.Tally memory tally
        ) = l2plugin.getProposal(0);

        assertEq(open, false);
        assertEq(parentProposalId, uint256(1));
        assertEq(tally.yes, 10 ether);
    }
}
