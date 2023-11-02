// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Extension} from "@email-wallet/src/interfaces/Extension.sol";
import {EmailWalletCore} from "@email-wallet/src/EmailWalletCore.sol";
import {TokenRegistry} from "@email-wallet/src/utils/TokenRegistry.sol";
import {ExtensionQuery} from "./ExtensionQuery.sol";
import {StringUtils} from "./StringUtils.sol";

library EmailWalletHelper {
    function registerUnclaimedStateAsExtension(
        EmailWalletCore core,
        bytes memory state
    ) internal {
        core.registerUnclaimedStateAsExtension(address(this), state);
    }

    function registerUnclaimedStateAsExtension(
        EmailWalletCore core,
        address extensionAddr,
        bytes memory state
    ) internal {
        core.registerUnclaimedStateAsExtension(extensionAddr, state);
    }

    function executeOnWallet(
        EmailWalletCore core,
        address target,
        bytes calldata data
    ) internal {
        core.executeAsExtension(target, data);
    }

    function requestTokenFromWallet(
        EmailWalletCore core,
        address tokenAddr,
        uint256 amount
    ) internal {
        core.requestTokenAsExtension(tokenAddr, amount);
    }

    function getTokenAddressOfName(
        EmailWalletCore core,
        string memory name
    ) internal view returns (address) {
        require(bytes(name).length > 0, "name must not be empty");
        TokenRegistry tokenRegistry = core.tokenRegistry();
        return tokenRegistry.getTokenAddress(name);
    }

    function getTokenNameOfAddress(
        EmailWalletCore core,
        address tokenAddr
    ) internal view returns (string memory) {
        require(tokenAddr != address(0), "tokenAddr must not be zero");
        TokenRegistry tokenRegistry = core.tokenRegistry();
        return tokenRegistry.getTokenNameOfAddress(tokenAddr);
    }
}
