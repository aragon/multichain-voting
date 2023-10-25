// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.17;

import { IDAO } from "@aragon/osx/core/dao/IDAO.sol";
import { IMajorityVoting } from "@aragon/osx/plugins/governance/majority-voting/IMajorityVoting.sol";

/// @title ICrossChainMajorityVoting
/// @author Aragon Association - 2023-2024
/// @notice The interface of crosschain majority voting plugin.
/// @custom:security-contact sirt@aragon.org
interface ICrossChainVoting is IMajorityVoting {

    /// @notice A container for the majority voting settings that will be applied as parameters on proposal creation.
    /// @param bridge 
    /// @param proxyDAO 
    /// @param proxyPlugin 
    struct VotingRelayer {
        address bridge;
        IDAO proxyDAO;
        address proxyPlugin;
    }

    /// @notice A container for the results being bridged from another chain
    /// @param 
    struct VotingResults {
        uint256 yes;
        uint256 nay;
        uint256 abstain;
    }

    /// @notice Returns the support threshold parameter stored in the voting settings.
    /// @param votingResults The results being bridged from the other chain
    function aggregateResults(VotingResults memory votingResults) external;

    /// @notice Function that send the proposal details to the approved networks
    /// @param proposalId The id of the proposal to be relayed 
    function propagateProposal(uint256 proposalId) external;
}
