// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import { PermissionLib } from "@aragon/osx/core/permission/PermissionLib.sol";
import { PluginSetup, IPluginSetup } from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import { SimpleStorage } from "./SimpleStorage.sol";

/// @title SimpleStorageSetup build 1
contract SimpleStorageSetup is PluginSetup {
    address private immutable IMPLEMEMTATION;

    constructor() {
        IMPLEMEMTATION = address(new SimpleStorage());
    }

    /// @inheritdoc IPluginSetup
    function prepareInstallation(
        address _dao,
        bytes memory _data
    )
        external
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        uint256 number = abi.decode(_data, (uint256));

        plugin =
            createERC1967Proxy(IMPLEMEMTATION, abi.encodeWithSelector(SimpleStorage.initialize.selector, _dao, number));

        PermissionLib.MultiTargetPermission[] memory permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("STORE_PERMISSION")
        });

        preparedSetupData.permissions = permissions;
    }

    /// @inheritdoc IPluginSetup
    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    )
        external
        pure
        returns (PermissionLib.MultiTargetPermission[] memory permissions)
    {
        permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("STORE_PERMISSION")
        });
    }

    /// @inheritdoc IPluginSetup
    function implementation() external view returns (address) {
        return IMPLEMEMTATION;
    }
}
