// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { console2 } from "forge-std/console2.sol";

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { DAO } from "@aragon/osx/core/dao/DAO.sol";
import { DAOMock } from "@aragon/osx/test/dao/DAOMock.sol";
import { IPluginSetup } from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import { DaoUnauthorized } from "@aragon/osx/core/utils/auth.sol";

import { AragonTestBase } from "./base/AragonTestBase.sol";

import { SimpleStorageSetup } from "../src/SimpleStorageSetup.sol";
import { SimpleStorage } from "../src/SimpleStorage.sol";

abstract contract SimpleStorageTest is AragonTestBase {
    DAO internal dao;
    SimpleStorage internal plugin;
    SimpleStorageSetup internal setup;
    uint256 internal constant NUMBER = 420;

    function setUp() public virtual {
        setup = new SimpleStorageSetup();
        bytes memory setupData = abi.encode(NUMBER);

        (DAO _dao, address _plugin) = _createDaoWithPlugin(setup, setupData);

        dao = _dao;
        plugin = SimpleStorage(_plugin);
    }
}

contract SimpleStorageInitializeTest is SimpleStorageTest {
    function setUp() public override {
        super.setUp();
    }

    function test_initialize() public {
        assertEq(address(plugin.dao()), address(dao));
        assertEq(plugin.number(), NUMBER);
    }

    function test_reverts_if_reinitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        plugin.initialize(dao, 69);
    }
}

contract SimpleStorageStoreNumberTest is SimpleStorageTest {
    function setUp() public override {
        super.setUp();
    }

    function test_store_number() public {
        vm.prank(address(dao));
        plugin.storeNumber(69);
        assertEq(plugin.number(), 69);
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

        plugin.storeNumber(69);
    }
}
