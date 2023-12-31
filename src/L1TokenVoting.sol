// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.17;

import {IVotesUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IMembership} from "@aragon/osx/core/plugin/membership/IMembership.sol";
import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {RATIO_BASE, _applyRatioCeiled} from "@aragon/osx/plugins/utils/Ratio.sol";

import {L1MajorityVotingBase} from "./L1MajorityVotingBase.sol";
import {NonblockingLzApp} from "./lzApp/NonblockingLzApp.sol";

/// @title L1TokenVoting
/// @author Aragon Association - 2021-2023
/// @notice The majority voting implementation using an [OpenZeppelin `Votes`](https://docs.openzeppelin.com/contracts/4.x/api/governance#Votes) compatible governance token.
/// @dev This contract inherits from `L1MajorityVotingBase` and implements the `IL2MajorityVoting` interface.
/// @custom:security-contact sirt@aragon.org
contract L1TokenVoting is IMembership, L1MajorityVotingBase, NonblockingLzApp {
    using SafeCastUpgradeable for uint256;

    /// @notice The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID of the contract.
    bytes4 internal constant TOKEN_VOTING_INTERFACE_ID =
        this.initialize.selector ^ this.getVotingToken.selector;

    /// @notice An [OpenZeppelin `Votes`](https://docs.openzeppelin.com/contracts/4.x/api/governance#Votes) compatible contract referencing the token being used for voting.
    IVotesUpgradeable private votingToken;

    /// @notice Thrown if the voting power is zero
    error NoVotingPower();

    /// @notice bridge is not yet set
    error BridgeSettingsNotSet();

    /// @notice Initializes the component.
    /// @dev This method is required to support [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822).
    /// @param _dao The IDAO interface of the associated DAO.
    /// @param _votingSettings The voting settings.
    /// @param _token The [ERC-20](https://eips.ethereum.org/EIPS/eip-20) token used for voting.
    function initialize(
        IDAO _dao,
        VotingSettings calldata _votingSettings,
        IVotesUpgradeable _token
    ) external initializer {
        __MajorityVotingBase_init(_dao, _votingSettings);

        votingToken = _token;

        emit MembershipContractAnnounced({definingContract: address(_token)});
    }

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param _interfaceId The ID of the interface.
    /// @return Returns `true` if the interface is supported.
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == TOKEN_VOTING_INTERFACE_ID ||
            _interfaceId == type(IMembership).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice getter function for the voting token.
    /// @dev public function also useful for registering interfaceId and for distinguishing from majority voting interface.
    /// @return The token used for voting.
    function getVotingToken() public view returns (IVotesUpgradeable) {
        return votingToken;
    }

    /// @inheritdoc L1MajorityVotingBase
    function totalVotingPower(uint256 _blockNumber) public view override returns (uint256) {
        return votingToken.getPastTotalSupply(_blockNumber);
    }

    /// @inheritdoc L1MajorityVotingBase
    function createProposal(
        bytes calldata _metadata,
        IDAO.Action[] calldata _actions,
        uint256 _allowFailureMap,
        uint64 _startDate,
        uint64 _endDate,
        VoteOption _voteOption
    ) external payable override returns (uint256 proposalId) {
        // Check that either `_msgSender` owns enough tokens or has enough voting power from being a delegatee.
        {
            uint256 minProposerVotingPower_ = minProposerVotingPower();

            if (minProposerVotingPower_ != 0) {
                // Because of the checks in `TokenVotingSetup`, we can assume that `votingToken` is an [ERC-20](https://eips.ethereum.org/EIPS/eip-20) token.
                if (
                    votingToken.getVotes(_msgSender()) < minProposerVotingPower_ &&
                    IERC20Upgradeable(address(votingToken)).balanceOf(_msgSender()) <
                    minProposerVotingPower_
                ) {
                    revert ProposalCreationForbidden(_msgSender());
                }
            }
        }

        uint256 snapshotBlock;
        unchecked {
            snapshotBlock = block.number - 1; // The snapshot block must be mined already to protect the transaction against backrunning transactions causing census changes.
        }

        uint256 totalVotingPower_ = totalVotingPower(snapshotBlock);

        if (totalVotingPower_ == 0) {
            revert NoVotingPower();
        }

        (_startDate, _endDate) = _validateProposalDates(_startDate, _endDate);

        proposalId = _createProposal({
            _creator: _msgSender(),
            _metadata: _metadata,
            _startDate: _startDate,
            _endDate: _endDate,
            _actions: _actions,
            _allowFailureMap: _allowFailureMap
        });

        // Store proposal related information
        Proposal storage proposal_ = proposals[proposalId];

        proposal_.parameters.startDate = _startDate;
        proposal_.parameters.endDate = _endDate;
        proposal_.parameters.snapshotBlock = snapshotBlock.toUint64();
        proposal_.parameters.supportThreshold = supportThreshold();
        proposal_.parameters.minVotingPower = _applyRatioCeiled(
            totalVotingPower_,
            minParticipation()
        );

        // Reduce costs
        if (_allowFailureMap != 0) {
            proposal_.allowFailureMap = _allowFailureMap;
        }

        // Bridge the proposal over to the L2
        bytes memory encodedMessage = abi.encode(proposalId, _startDate, _endDate);

        if (
            bridgeSettings.bridge != address(0) ||
            bridgeSettings.chainId != uint16(0) ||
            address(bridgeSettings.childDAO) != address(0)
        ) {
            _lzSend({
                _dstChainId: bridgeSettings.chainId,
                _payload: encodedMessage,
                _refundAddress: payable(msg.sender),
                _zroPaymentAddress: address(0),
                _adapterParams: bytes(""),
                _nativeFee: address(this).balance
            });
        }

        for (uint256 i; i < _actions.length; ) {
            proposal_.actions.push(_actions[i]);
            unchecked {
                ++i;
            }
        }

        if (_voteOption != VoteOption.None) {
            vote(proposalId, _voteOption);
        }
    }

    /// @inheritdoc IMembership
    function isMember(address _account) external view returns (bool) {
        // A member must own at least one token or have at least one token delegated to her/him.
        return
            votingToken.getVotes(_account) > 0 ||
            IERC20Upgradeable(address(votingToken)).balanceOf(_account) > 0;
    }

    /// @notice Updates the bridge settings.
    /// @param _bridgeSettings The new voting settings.
    function updateBridgeSettings(
        L1MajorityVotingBase.BridgeSettings calldata _bridgeSettings
    ) external virtual auth(UPDATE_BRIDGE_SETTINGS_PERMISSION_ID) {
        bridgeSettings = _bridgeSettings;
        _setEndpoint(_bridgeSettings.bridge);
        bytes memory remoteAndLocalAddresses = abi.encodePacked(
            _bridgeSettings.childPlugin,
            address(this)
        );
        _setTrustedRemoteAddress(_bridgeSettings.chainId, remoteAndLocalAddresses);
    }

    /// @inheritdoc L1MajorityVotingBase
    function _vote(uint256 _proposalId, VoteOption _voteOption, address _voter) internal override {
        Proposal storage proposal_ = proposals[_proposalId];

        // This could re-enter, though we can assume the governance token is not malicious
        uint256 votingPower = votingToken.getPastVotes(_voter, proposal_.parameters.snapshotBlock);
        VoteOption state = proposal_.voters[_voter];

        // If voter had previously voted, decrease count
        if (state == VoteOption.Yes) {
            proposal_.tally.yes = proposal_.tally.yes - votingPower;
        } else if (state == VoteOption.No) {
            proposal_.tally.no = proposal_.tally.no - votingPower;
        } else if (state == VoteOption.Abstain) {
            proposal_.tally.abstain = proposal_.tally.abstain - votingPower;
        }

        // write the updated/new vote for the voter.
        if (_voteOption == VoteOption.Yes) {
            proposal_.tally.yes = proposal_.tally.yes + votingPower;
        } else if (_voteOption == VoteOption.No) {
            proposal_.tally.no = proposal_.tally.no + votingPower;
        } else if (_voteOption == VoteOption.Abstain) {
            proposal_.tally.abstain = proposal_.tally.abstain + votingPower;
        }

        proposal_.voters[_voter] = _voteOption;

        emit VoteCast({
            proposalId: _proposalId,
            voter: _voter,
            voteOption: _voteOption,
            votingPower: votingPower
        });
    }

    /// @inheritdoc L1MajorityVotingBase
    function _canVote(
        uint256 _proposalId,
        address _account,
        VoteOption _voteOption
    ) internal view override returns (bool) {
        Proposal storage proposal_ = proposals[_proposalId];

        // The proposal vote hasn't started or has already ended.
        if (!_isProposalOpen(proposal_)) {
            return false;
        }

        // The voter votes `None` which is not allowed.
        if (_voteOption == VoteOption.None) {
            return false;
        }

        // The voter has no voting power.
        if (votingToken.getPastVotes(_account, proposal_.parameters.snapshotBlock) == 0) {
            return false;
        }

        // The voter has already voted but vote replacment is not allowed.
        if (proposal_.voters[_account] != VoteOption.None) {
            return false;
        }

        return true;
    }

    // Function to receive the votes
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal override {
        // It's already checkec if the sender is a trustedRemote
        (uint256 proposalId, Tally memory tally) = abi.decode(_payload, (uint256, Tally));

        Proposal storage proposal_ = proposals[proposalId];
        proposal_.tally.yes += tally.yes;
        proposal_.tally.no += tally.no;
        proposal_.tally.abstain += tally.abstain;

        emit VoteCast({
            proposalId: proposalId,
            voter: address(0),
            voteOption: L1MajorityVotingBase.VoteOption.Yes,
            votingPower: tally.yes
        });
        emit VoteCast({
            proposalId: proposalId,
            voter: address(0),
            voteOption: L1MajorityVotingBase.VoteOption.No,
            votingPower: tally.no
        });
        emit VoteCast({
            proposalId: proposalId,
            voter: address(0),
            voteOption: L1MajorityVotingBase.VoteOption.Abstain,
            votingPower: tally.abstain
        });
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[47] private __gap;
}
