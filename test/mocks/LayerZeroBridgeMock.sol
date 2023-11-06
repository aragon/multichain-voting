// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.17;

import { console2 } from "forge-std/console2.sol";
import { ILayerZeroReceiver } from "../../src/interfaces/ILayerZeroReceiver.sol";
import { ILayerZeroSender } from "../../src/interfaces/ILayerZeroSender.sol";

contract LayerZeroBridgeMock is ILayerZeroSender {
    function send(
        uint16 _dstChainId, 
        bytes calldata _remoteAndLocalAddresses, 
        bytes calldata _payload, 
        address payable _refundAddress, 
        address _zroPaymentAddress, 
        bytes calldata _adapterParams
    ) external payable {
        (address remoteAddress, address localAddress) = abi.decode(_remoteAndLocalAddresses, (address, address));
        console2.log("Calling plugin:");
        console2.log(remoteAddress);
        ILayerZeroReceiver(remoteAddress).lzReceive(_dstChainId, _remoteAndLocalAddresses, uint64(0), _payload);
    }
}