// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Extension} from "@email-wallet/src/interfaces/Extension.sol";
import {EmailWalletCore} from "@email-wallet/src/EmailWalletCore.sol";
import {TokenRegistry} from "@email-wallet/src/utils/TokenRegistry.sol";
import {StringUtils} from "./StringUtils.sol";

// import "solidity-stringutils/src/strings.sol";

abstract contract ExtensionQuery {
    // EmailWalletCore public immutable core;
    string[][] public queryTemplates;

    constructor() {
        string[] memory queryRawTemplates = defineQueryTemplates();
        queryTemplates = new string[][](queryRawTemplates.length);
        for (uint i = 0; i < queryRawTemplates.length; i++) {
            string[] memory splited = StringUtils.splitString(
                queryRawTemplates[i],
                " "
            );
            queryTemplates[i] = new string[](splited.length);
            for (uint j = 0; j < splited.length; j++) {
                queryTemplates[i][j] = splited[j];
            }
        }
    }

    function defineQueryTemplates()
        internal
        pure
        virtual
        returns (string[] memory)
    {
        return new string[](0);
    }

    function query(
        uint8 templateIndex,
        bytes[] memory subjectParams,
        address wallet,
        bool hasEmailRecipient,
        address recipientETHAddr
    ) public view virtual returns (string memory) {
        templateIndex;
        subjectParams;
        wallet;
        hasEmailRecipient;
        recipientETHAddr;
        return "";
    }
}
