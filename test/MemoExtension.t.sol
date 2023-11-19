// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {EmailWalletCoreTestHelper} from "@email-wallet/test/helpers/EmailWalletCoreTestHelper.sol";
import {ExtensionHandler} from "@email-wallet/src/handlers/ExtensionHandler.sol";
import "@email-wallet/src/interfaces/Commands.sol";
import {StringUtils} from "../src/helpers/StringUtils.sol";
import "../src/MemoExtension.sol";

contract MemoExtensionTest is EmailWalletCoreTestHelper {
    using StringUtils for *;

    MemoExtension memoExtension;

    function setUp() public override {
        super.setUp();
        _registerRelayer();
        _registerAndInitializeAccount();

        address extensionDev = vm.addr(3);
        vm.startPrank(extensionDev);
        memoExtension = new MemoExtension(address(core));
        ExtensionHandler extensionHandler = core.extensionHandler();
        extensionHandler.publishExtension(
            memoExtension.extensionName(),
            address(memoExtension),
            memoExtension.getExecutionTemplates(),
            memoExtension.maxExecutionGas()
        );
        vm.stopPrank();

        EmailOp memory emailOp = _getBaseEmailOp();
        emailOp.command = Commands.INSTALL_EXTENSION;
        emailOp.extensionName = memoExtension.extensionName();
        emailOp.maskedSubject = string.concat(
            "Install extension ",
            memoExtension.extensionName()
        );
        emailOp.emailNullifier = bytes32(uint256(93845));

        vm.startPrank(relayer);
        core.handleEmailOp(emailOp);
        vm.stopPrank();
    }

    function test_TemplateZero() public {
        string memory contents = "Hello world!";
        string memory subject = string.concat("Memo ", contents);

        EmailOp memory emailOp = _getBaseEmailOp();
        emailOp.command = "Memo";
        emailOp.maskedSubject = subject;
        emailOp.emailNullifier = bytes32(uint256(23914));
        emailOp.extensionParams.subjectTemplateIndex = 0;
        emailOp.extensionParams.subjectParams = new bytes[](1);
        emailOp.extensionParams.subjectParams[0] = abi.encode(contents);

        vm.startPrank(relayer);
        (bool success, bytes memory err, , ) = core.handleEmailOp(emailOp);
        require(success, string(err));
        vm.stopPrank();

        bytes32 memoId = memoExtension.idsOfWriter(walletAddr, 0);
        assertEq(
            memoId,
            emailOp.emailNullifier,
            "memoIds[0] should be emailNullifier"
        );
        assertEq(
            memoExtension.idsOfContents(contents, 0),
            emailOp.emailNullifier,
            "idsOfContents[memo] should be emailNullifier"
        );
        MemoExtension.Memo memory memo = memoExtension.getMemoOfId(memoId);
        assertEq(memo.writer, walletAddr, "memo.writer should be walletAddr");
        assertEq(memo.contents, contents, "memo.content should be memo");
        assertEq(
            memo.sentTimestamp,
            block.timestamp,
            "memo.sentTimestamp should be block.timestamp"
        );
        assertEq(
            memo.receivedTimestamp,
            0,
            "memo.receivedTimestamp should be zero"
        );
        assertEq(memo.recipient, address(0), "memo.recipient should be zero");
        assertEq(memo.tokenAddr, address(0), "memo.tokenAddr should be zero");
        assertEq(memo.tokenAmount, 0, "memo.tokenAmount should be zero");
        assertEq(memo.isReceived, true, "memo.isReceived should be true");

        bytes[] memory querySubjectParams = new bytes[](1);
        querySubjectParams[0] = abi.encode(uint256(memoId).toHexString(32));
        string memory queried = memoExtension.query(
            0,
            querySubjectParams,
            walletAddr,
            false,
            address(0)
        );
        assertEq(
            queried,
            string.concat(
                "Memo of id ",
                uint256(memoId).toHexString(32),
                " is found. writer: ",
                memo.writer.toHexString(),
                ", sent timestamp: ",
                memo.sentTimestamp.toString(),
                ", received timestamp: ",
                memo.receivedTimestamp.toString(),
                ", contents: ",
                memo.contents,
                memo.isReceived ? ", received." : ", not received."
            ),
            "query result is invalid"
        );
    }

    function test_TemplateOne() public {
        string memory contents = "Hello world!";
        bytes32 recipientEmailAddrCommit = bytes32(uint256(326733));
        string memory subject = string.concat("Memo ", contents, " for ");

        EmailOp memory emailOp = _getBaseEmailOp();
        emailOp.command = "Memo";
        emailOp.maskedSubject = subject;
        emailOp.emailNullifier = bytes32(uint256(2391424));
        emailOp.extensionParams.subjectTemplateIndex = 1;
        emailOp.extensionParams.subjectParams = new bytes[](1);
        emailOp.extensionParams.subjectParams[0] = abi.encode(contents);
        emailOp.hasEmailRecipient = true;
        emailOp.recipientEmailAddrCommit = recipientEmailAddrCommit;
        emailOp.feeTokenName = "DAI";

        vm.startPrank(relayer);
        vm.deal(relayer, unclaimedStateClaimGas * maxFeePerGas);
        daiToken.freeMint(walletAddr, 10 ether); // For fee reibursement
        (bool success, bytes memory err, , uint256 registeredUnclaimId) = core
            .handleEmailOp{value: unclaimedStateClaimGas * maxFeePerGas}(
            emailOp
        );
        require(success, string(err));
        vm.stopPrank();

        bytes32 memoId = memoExtension.idsOfWriter(walletAddr, 0);
        assertEq(
            memoId,
            emailOp.emailNullifier,
            "memoId should be emailNullifier"
        );
        assertEq(
            memoExtension.idsOfContents(contents, 0),
            emailOp.emailNullifier,
            "idsOfContents[memo] should be emailNullifier"
        );
        MemoExtension.Memo memory memo = memoExtension.getMemoOfId(
            emailOp.emailNullifier
        );
        assertEq(memo.writer, walletAddr, "memo.writer should be walletAddr");
        assertEq(memo.contents, contents, "memo.content should be memo");
        assertEq(
            memo.sentTimestamp,
            block.timestamp,
            "memo.sentTimestamp should be block.timestamp"
        );
        assertEq(
            memo.receivedTimestamp,
            0,
            "memo.receivedTimestamp should be zero"
        );
        assertEq(memo.recipient, address(0), "memo.recipient should be zero");
        assertEq(memo.tokenAddr, address(0), "memo.tokenAddr should be zero");
        assertEq(memo.tokenAmount, 0, "memo.tokenAmount should be zero");
        assertEq(memo.isReceived, false, "memo.isReceived should be true");

        vm.startPrank(relayer);
        unclaimsHandler.claimUnclaimedState(
            registeredUnclaimId,
            emailAddrPointer,
            mockProof
        );
        vm.stopPrank();

        memo = memoExtension.getMemoOfId(emailOp.emailNullifier);
        assertEq(memo.recipient, walletAddr, "memo.recipient should be zero");
        assertEq(memo.isReceived, true, "memo.isReceived should be true");
    }

    function test_TemplateTwo() public {
        string memory contents = "Hello world!";
        bytes32 recipientEmailAddrCommit = bytes32(uint256(326733));
        string memory subject = string.concat(
            "Memo ",
            contents,
            " with sending 1.23 DAI to "
        );

        EmailOp memory emailOp = _getBaseEmailOp();
        emailOp.command = "Memo";
        emailOp.maskedSubject = subject;
        emailOp.emailNullifier = bytes32(uint256(2391424));
        emailOp.extensionParams.subjectTemplateIndex = 2;
        emailOp.extensionParams.subjectParams = new bytes[](2);
        emailOp.extensionParams.subjectParams[0] = abi.encode(contents);
        emailOp.extensionParams.subjectParams[1] = abi.encode(
            1.23 ether,
            "DAI"
        );
        emailOp.hasEmailRecipient = true;
        emailOp.recipientEmailAddrCommit = recipientEmailAddrCommit;
        emailOp.feeTokenName = "DAI";

        vm.startPrank(relayer);
        vm.deal(relayer, unclaimedStateClaimGas * maxFeePerGas);
        daiToken.freeMint(walletAddr, 10 ether); // For fee reibursement
        (bool success, bytes memory err, , uint256 registeredUnclaimId) = core
            .handleEmailOp{value: unclaimedStateClaimGas * maxFeePerGas}(
            emailOp
        );
        require(success, string(err));
        vm.stopPrank();

        bytes32 memoId = memoExtension.idsOfWriter(walletAddr, 0);
        assertEq(
            memoId,
            emailOp.emailNullifier,
            "memoId should be emailNullifier"
        );
        assertEq(
            memoExtension.idsOfContents(contents, 0),
            emailOp.emailNullifier,
            "idsOfContents[memo] should be emailNullifier"
        );
        MemoExtension.Memo memory memo = memoExtension.getMemoOfId(
            emailOp.emailNullifier
        );
        assertEq(memo.writer, walletAddr, "memo.writer should be walletAddr");
        assertEq(memo.contents, contents, "memo.content should be memo");
        assertEq(
            memo.sentTimestamp,
            block.timestamp,
            "memo.sentTimestamp should be block.timestamp"
        );
        assertEq(
            memo.receivedTimestamp,
            0,
            "memo.receivedTimestamp should be zero"
        );
        assertEq(memo.recipient, address(0), "memo.recipient should be zero");
        assertEq(
            memo.tokenAddr,
            address(daiToken),
            "memo.tokenAddr should be weth"
        );
        assertEq(
            memo.tokenAmount,
            1.23 ether,
            "memo.tokenAmount should be 1.23 ether"
        );
        assertEq(memo.isReceived, false, "memo.isReceived should be true");

        vm.startPrank(relayer);
        unclaimsHandler.claimUnclaimedState(
            registeredUnclaimId,
            emailAddrPointer,
            mockProof
        );
        vm.stopPrank();

        memo = memoExtension.getMemoOfId(emailOp.emailNullifier);
        assertEq(memo.recipient, walletAddr, "memo.recipient should be zero");
        assertEq(memo.isReceived, true, "memo.isReceived should be true");
    }
}
