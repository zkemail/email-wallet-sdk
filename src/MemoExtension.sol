// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@email-wallet/src/interfaces/Types.sol";
import {ExtensionBase} from "./helpers/ExtensionBase.sol";
import {StringUtils} from "./helpers/StringUtils.sol";
import {EmailWalletHelper} from "./helpers/EmailWalletHelper.sol";

contract MemoExtension is ExtensionBase {
    using StringUtils for *;
    using EmailWalletHelper for *;

    struct Memo {
        bytes32 memoId;
        address writer;
        uint sentTimestamp;
        uint receivedTimestamp;
        string contents;
        address recipient;
        address tokenAddr;
        uint tokenAmount;
        bool isReceived;
    }

    struct State {
        bytes32 memoId;
    }

    mapping(bytes32 => Memo) public memoOfId;
    mapping(address => bytes32[]) public idsOfWriter;
    mapping(string => bytes32[]) public idsOfContents;
    mapping(address => bytes32[]) public idsOfRecipient;

    constructor(address coreAddr) ExtensionBase(coreAddr) {}

    function defineExecutionTemplates()
        internal
        pure
        override
        returns (string[] memory)
    {
        string[] memory templates = new string[](3);
        templates[0] = "Memo {string}";
        templates[1] = "Memo {string} for {recipient}";
        templates[
            2
        ] = "Memo {string} with sending {tokenAmount} to {recipient}";
        return templates;
    }

    function execute(
        uint8 templateIndex,
        bytes[] memory subjectParams,
        address wallet,
        bool hasEmailRecipient,
        address recipientETHAddr,
        bytes32 emailNullifier
    ) external override onlyEmailWallet {
        require(
            templateIndex == 0 || templateIndex == 1 || templateIndex == 2,
            "invalid template index"
        );
        string memory contents = abi.decode(subjectParams[0], (string));
        require(bytes(contents).length > 0, "contents must not be empty");
        if (templateIndex == 0) {
            executeTemplateZero(wallet, emailNullifier, contents);
        } else if (templateIndex == 1) {
            executeTemplateOne(
                wallet,
                hasEmailRecipient,
                recipientETHAddr,
                emailNullifier,
                contents
            );
        } else if (templateIndex == 2) {
            executeTemplateTwo(
                subjectParams,
                wallet,
                hasEmailRecipient,
                recipientETHAddr,
                emailNullifier,
                contents
            );
        }
    }

    function registerUnclaimedState(
        UnclaimedState memory unclaimedState,
        bool isInternal
    ) public view override onlyEmailWallet {
        require(isInternal, "only internal registration is allowed");
        State memory state = abi.decode(unclaimedState.state, (State));
        require(memoOfId[state.memoId].writer != address(0), "memo not found");
        require(
            memoOfId[state.memoId].writer == unclaimedState.sender,
            "invalid sender"
        );
    }

    function claimUnclaimedState(
        UnclaimedState memory unclaimedState,
        address recipientWallet
    ) external override onlyEmailWallet {
        require(recipientWallet != address(0), "invalid recipientWallet");
        State memory state = abi.decode(unclaimedState.state, (State));
        bytes32 memoId = state.memoId;
        memoOfId[memoId].receivedTimestamp = block.timestamp;
        memoOfId[memoId].recipient = recipientWallet;
        memoOfId[memoId].isReceived = true;
        idsOfRecipient[recipientWallet].push(memoId);
        Memo memory memo = memoOfId[memoId];
        if (memo.tokenAmount > 0 && memo.tokenAddr != address(0)) {
            ERC20(memo.tokenAddr).transfer(recipientWallet, memo.tokenAmount);
        }
    }

    function voidUnclaimedState(
        UnclaimedState memory unclaimedState
    ) external override onlyEmailWallet {
        State memory state = abi.decode(unclaimedState.state, (State));
        bytes32 memoId = state.memoId;
        Memo memory memo = memoOfId[memoId];
        if (memo.tokenAmount > 0 && memo.tokenAddr != address(0)) {
            ERC20(memo.tokenAddr).transfer(memo.writer, memo.tokenAmount);
        }
    }

    function defineExtensionName()
        internal
        pure
        override
        returns (string memory)
    {
        return "Memo-v1.0.0";
    }

    function defineQueryTemplates()
        internal
        pure
        override
        returns (string[] memory)
    {
        string[] memory templates = new string[](5);
        templates[0] = "Memo of id {string}";
        templates[1] = "Memo ids sent by {address}";
        templates[2] = "Memo ids with the contents of {string}";
        templates[3] = "Memo ids received by {recipient}";
        templates[4] = "Memo ids sent by me";
        return templates;
    }

    function query(
        uint8 templateIndex,
        bytes[] memory subjectParams,
        address wallet,
        bool hasEmailRecipient,
        address recipientETHAddr
    ) public view override returns (string memory) {
        hasEmailRecipient;
        if (templateIndex == 0) {
            require(subjectParams.length == 1, "invalid subjectParams length");
            string memory memoIdHex = abi.decode(subjectParams[0], (string));
            bytes32 memoId = memoIdHex.hexToBytes32();
            Memo memory memo = memoOfId[memoId];
            if (memo.writer == address(0)) {
                return string.concat("memo of id ", memoIdHex, " is not found");
            } else {
                string memory reply = string.concat(
                    "Memo of id ",
                    memoIdHex,
                    " is found. writer: ",
                    memo.writer.toHexString(),
                    ", sent timestamp: ",
                    memo.sentTimestamp.toString(),
                    ", received timestamp: ",
                    memo.receivedTimestamp.toString(),
                    ", contents: ",
                    memo.contents,
                    memo.isReceived ? ", received." : ", not received."
                );
                if (memo.recipient != address(0)) {
                    reply = string.concat(
                        reply,
                        ", recipient: ",
                        memo.recipient.toHexString()
                    );
                }
                if (memo.tokenAddr != address(0)) {
                    uint8 decimals = ERC20(memo.tokenAddr).decimals();
                    reply = string.concat(
                        reply,
                        ", sent token: ",
                        memo.tokenAmount.uintToDecimalString(decimals),
                        " ",
                        core.getTokenNameOfAddress(memo.tokenAddr)
                    );
                }
                return reply;
            }
        } else if (templateIndex == 1) {
            require(subjectParams.length == 1, "invalid subjectParams length");
            address writer = abi.decode(subjectParams[0], (address));
            bytes32[] memory memoIds = idsOfWriter[writer];
            string memory reply = "Found memo ids: ";
            for (uint i = 0; i < memoIds.length; i++) {
                reply = string.concat(reply, uint(memoIds[i]).toHexString(32));
                if (i == memoIds.length - 1) {
                    reply = string.concat(reply, ".");
                } else {
                    reply = string.concat(reply, ", ");
                }
            }
            return reply;
        } else if (templateIndex == 2) {
            require(subjectParams.length == 1, "invalid subjectParams length");
            string memory contents = abi.decode(subjectParams[0], (string));
            bytes32[] memory memoIds = idsOfContents[contents];
            string memory reply = "Found memo ids: ";
            for (uint i = 0; i < memoIds.length; i++) {
                reply = string.concat(reply, uint(memoIds[i]).toHexString(32));
                if (i == memoIds.length - 1) {
                    reply = string.concat(reply, ".");
                } else {
                    reply = string.concat(reply, ", ");
                }
            }
            return reply;
        } else if (templateIndex == 3) {
            require(subjectParams.length == 1, "invalid subjectParams length");
            bytes32[] memory memoIds = idsOfRecipient[recipientETHAddr];
            string memory reply = "Found memo ids: ";
            for (uint i = 0; i < memoIds.length; i++) {
                reply = string.concat(reply, uint(memoIds[i]).toHexString(32));
                if (i == memoIds.length - 1) {
                    reply = string.concat(reply, ".");
                } else {
                    reply = string.concat(reply, ", ");
                }
            }
            return reply;
        } else if (templateIndex == 4) {
            bytes32[] memory memoIds = idsOfWriter[wallet];
            string memory reply = "Found memo ids: ";
            for (uint i = 0; i < memoIds.length; i++) {
                reply = string.concat(reply, uint(memoIds[i]).toHexString(32));
                if (i == memoIds.length - 1) {
                    reply = string.concat(reply, ".");
                } else {
                    reply = string.concat(reply, ", ");
                }
            }
            return reply;
        } else {
            return "Unsupported query template";
        }
    }

    function getMemoOfId(bytes32 memoId) public view returns (Memo memory) {
        return memoOfId[memoId];
    }

    function getMemoIdsOfWriter(
        address writer
    ) public view returns (bytes32[] memory) {
        return idsOfWriter[writer];
    }

    function getMemoIdsOfContents(
        string memory contents
    ) public view returns (bytes32[] memory) {
        return idsOfContents[contents];
    }

    function getMemoIdsOfRecipient(
        address recipient
    ) public view returns (bytes32[] memory) {
        return idsOfRecipient[recipient];
    }

    function executeTemplateZero(
        address wallet,
        bytes32 emailNullifier,
        string memory contents
    ) private {
        Memo memory memo = Memo(
            emailNullifier,
            wallet,
            block.timestamp,
            0,
            contents,
            address(0),
            address(0),
            0,
            true
        );
        memoOfId[memo.memoId] = memo;
        idsOfWriter[memo.writer].push(memo.memoId);
        idsOfContents[memo.contents].push(memo.memoId);
    }

    function executeTemplateOne(
        address wallet,
        bool hasEmailRecipient,
        address recipientETHAddr,
        bytes32 emailNullifier,
        string memory contents
    ) private {
        if (hasEmailRecipient) {
            State memory state = State(emailNullifier);
            bytes memory stateBytes = abi.encode(state);
            Memo memory memo = Memo(
                emailNullifier,
                wallet,
                block.timestamp,
                0,
                contents,
                address(0),
                address(0),
                0,
                false
            );
            memoOfId[memo.memoId] = memo;
            idsOfWriter[memo.writer].push(memo.memoId);
            idsOfContents[memo.contents].push(memo.memoId);
            core.registerUnclaimedStateAsExtension(stateBytes);
        } else {
            require(recipientETHAddr != address(0), "invalid recipientETHAddr");
            Memo memory memo = Memo(
                emailNullifier,
                wallet,
                block.timestamp,
                block.timestamp,
                contents,
                recipientETHAddr,
                address(0),
                0,
                true
            );
            memoOfId[memo.memoId] = memo;
            idsOfWriter[memo.writer].push(memo.memoId);
            idsOfContents[memo.contents].push(memo.memoId);
            idsOfRecipient[memo.recipient].push(memo.memoId);
        }
    }

    function executeTemplateTwo(
        bytes[] memory subjectParams,
        address wallet,
        bool hasEmailRecipient,
        address recipientETHAddr,
        bytes32 emailNullifier,
        string memory contents
    ) private {
        (uint256 tokenAmount, string memory tokenName) = abi.decode(
            subjectParams[1],
            (uint256, string)
        );
        require(tokenAmount > 0, "tokenAmount must be positive");
        address tokenAddr = core.getTokenAddressOfName(tokenName);
        require(tokenAddr != address(0), "invalid token name");
        if (hasEmailRecipient) {
            State memory state = State(emailNullifier);
            bytes memory stateBytes = abi.encode(state);
            Memo memory memo = Memo(
                emailNullifier,
                wallet,
                block.timestamp,
                0,
                contents,
                address(0),
                tokenAddr,
                tokenAmount,
                false
            );
            memoOfId[memo.memoId] = memo;
            idsOfWriter[memo.writer].push(memo.memoId);
            idsOfContents[memo.contents].push(memo.memoId);
            uint balance = ERC20(tokenAddr).balanceOf(address(this));
            core.requestTokenFromWallet(tokenAddr, tokenAmount);
            require(
                ERC20(tokenAddr).balanceOf(address(this)) - balance ==
                    tokenAmount,
                "token transfer failed"
            );
            core.registerUnclaimedStateAsExtension(stateBytes);
        } else {
            require(recipientETHAddr != address(0), "invalid recipientETHAddr");
            Memo memory memo = Memo(
                emailNullifier,
                wallet,
                block.timestamp,
                block.timestamp,
                contents,
                recipientETHAddr,
                tokenAddr,
                tokenAmount,
                true
            );
            memoOfId[memo.memoId] = memo;
            idsOfWriter[memo.writer].push(memo.memoId);
            idsOfContents[memo.contents].push(memo.memoId);
            idsOfRecipient[memo.recipient].push(memo.memoId);
        }
    }
}
