// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;

import {NonblockingLzApp} from "./lzApp/NonblockingLzApp.sol";
import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {L2TokenVoting} from "./L2TokenVoting.sol";
import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";

contract NonblockingLzDAOProxy is NonblockingLzApp {
    IDAO immutable dao;
    address immutable l1dao;

    constructor(ILayerZeroEndpoint lzBridge, IDAO _dao, address _l1dao) {
        dao = _dao;
        l1dao = _l1dao;

        _setEndpoint(address(lzBridge));
        bytes memory remoteAndLocalAddresses = abi.encodePacked(l1dao, address(this));
        _setTrustedRemoteAddress(1, remoteAndLocalAddresses);
    }

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        (bytes32 _callId, IDAO.Action[] memory _actions, uint256 _allowFailureMap) = abi.decode(
            _payload,
            (bytes32, IDAO.Action[], uint256)
        );
        dao.execute(_callId, _actions, _allowFailureMap);
    }
}
