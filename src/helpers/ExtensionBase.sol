// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Extension} from "@email-wallet/interfaces/Extension.sol";
import {EmailWalletCore} from "@email-wallet/EmailWalletCore.sol";
import {TokenRegistry} from "@email-wallet/utils/TokenRegistry.sol";
import {ExtensionQuery} from "./ExtensionQuery.sol";
import {StringUtils} from "./StringUtils.sol";

abstract contract ExtensionBase is Extension, ExtensionQuery {
    EmailWalletCore public immutable core;
    string[][] public executionTemplates;
    uint public maxExecutionGas;

    modifier onlyEmailWallet() {
        require(
            (msg.sender == address(core)) ||
                (msg.sender == address(core.unclaimsHandler())),
            "invalid sender"
        );
        _;
    }

    constructor(address coreAddr) {
        core = EmailWalletCore(payable(coreAddr));
        maxExecutionGas = defineMaxExecutionGas();
        string[] memory executionRawTemplates = defineExecutionTemplates();
        for (uint i = 0; i < executionRawTemplates.length; i++) {
            string[] memory splited = StringUtils.splitString(
                executionRawTemplates[i],
                " "
            );
            for (uint j = 0; j < splited.length; j++) {
                executionTemplates[i][j] = splited[j];
            }
        }
    }

    function getExecutionTemplates() public view returns (string[][] memory) {
        return executionTemplates;
    }

    function defineExecutionTemplates()
        internal
        pure
        virtual
        returns (string[] memory);

    function defineMaxExecutionGas() internal pure virtual returns (uint) {
        return 0.01 ether;
    }

    function registerUnclaimedStateAsExtension(bytes memory state) internal {
        core.registerUnclaimedStateAsExtension(address(this), state);
    }

    function registerUnclaimedStateAsExtension(
        address extensionAddr,
        bytes memory state
    ) internal {
        core.registerUnclaimedStateAsExtension(extensionAddr, state);
    }

    function executeAsExtension(address target, bytes calldata data) internal {
        core.executeAsExtension(target, data);
    }

    function requestTokenAsExtension(
        address tokenAddr,
        uint256 amount
    ) internal {
        core.requestTokenAsExtension(tokenAddr, amount);
    }

    function getTokenAddressOfName(
        string memory name
    ) internal view returns (address) {
        require(bytes(name).length > 0, "name must not be empty");
        TokenRegistry tokenRegistry = core.tokenRegistry();
        return tokenRegistry.getTokenAddress(name);
    }

    function getTokenNameOfAddress(
        address tokenAddr
    ) internal view returns (string memory) {
        require(tokenAddr != address(0), "tokenAddr must not be zero");
        TokenRegistry tokenRegistry = core.tokenRegistry();
        return tokenRegistry.getTokenNameOfAddress(tokenAddr);
    }
}
