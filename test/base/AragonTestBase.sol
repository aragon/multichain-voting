// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { IPluginSetup, PluginSetup } from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import { DAO } from "@aragon/osx/core/dao/DAO.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Test } from "forge-std/Test.sol";

contract AragonTestBase is Test {
    bytes internal EMPTY_BYTES;

    function _createDaoWithPlugin(IPluginSetup setup, bytes memory setupData) internal returns (DAO, address) {
        DAO _dao = DAO(payable(new ERC1967Proxy(address(new DAO()), EMPTY_BYTES)));
        _dao.initialize(EMPTY_BYTES, address(this), address(0), "");

        (address plugin, PluginSetup.PreparedSetupData memory preparedSetupData) =
            setup.prepareInstallation(address(_dao), setupData);

        _dao.applyMultiTargetPermissions(preparedSetupData.permissions);

        return (_dao, plugin);
    }

    function account(string memory label) internal returns (address addr) {
        (addr,) = accountAndKey(label);
    }

    function accountAndKey(string memory label) internal returns (address addr, uint256 pk) {
        pk = uint256(keccak256(abi.encodePacked(label)));
        addr = vm.addr(pk);
        vm.label(addr, label);
    }

    function timetravel(uint256 time) internal {
        vm.warp(block.timestamp + time);
    }

    function blocktravel(uint256 blocks) internal {
        vm.roll(block.number + blocks);
    }
}
