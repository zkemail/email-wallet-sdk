// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Extension} from "@email-wallet/src/interfaces/Extension.sol";
import {EmailWalletCore} from "@email-wallet/src/EmailWalletCore.sol";
import {TokenRegistry} from "@email-wallet/src/utils/TokenRegistry.sol";
import {ExtensionQuery} from "./ExtensionQuery.sol";
import {StringUtils} from "./StringUtils.sol";

abstract contract ExtensionBase is Extension, ExtensionQuery {
    EmailWalletCore public immutable core;
    string public extensionName;
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

    constructor(address coreAddr) ExtensionQuery() {
        core = EmailWalletCore(payable(coreAddr));
        extensionName = defineExtensionName();
        maxExecutionGas = defineMaxExecutionGas();
        string[] memory executionRawTemplates = defineExecutionTemplates();
        executionTemplates = new string[][](executionRawTemplates.length);
        for (uint i = 0; i < executionRawTemplates.length; i++) {
            string[] memory splited = StringUtils.splitString(
                executionRawTemplates[i],
                " "
            );
            executionTemplates[i] = new string[](splited.length);
            for (uint j = 0; j < splited.length; j++) {
                executionTemplates[i][j] = splited[j];
            }
        }
    }

    function getExecutionTemplates() public view returns (string[][] memory) {
        return executionTemplates;
    }

    function defineExtensionName()
        internal
        pure
        virtual
        returns (string memory);

    function defineExecutionTemplates()
        internal
        pure
        virtual
        returns (string[] memory);

    function defineMaxExecutionGas() internal pure virtual returns (uint) {
        return 0.01 ether;
    }
}
