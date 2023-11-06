// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MemoExtension.sol";
import {EmailWalletCore} from "@email-wallet/src/EmailWalletCore.sol";
import {ExtensionHandler} from "@email-wallet/src/handlers/ExtensionHandler.sol";

contract Deploy is Script {
    uint256 constant maxFeePerGas = 2 gwei;
    uint256 constant emailValidityDuration = 1 hours;
    uint256 constant unclaimedFundClaimGas = 450000;
    uint256 constant unclaimedStateClaimGas = 500000;
    uint256 constant unclaimsExpiryDuration = 30 days;

    string[][] nftExtTemplates = new string[][](3);
    string[][] uniswapExtTemplates = new string[][](1);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            console.log("PRIVATE_KEY env var not set");
            return;
        }
        address _core = vm.envAddress("EMAIL_WALLET_CORE");
        if (_core == address(0)) {
            console.log("EMAIL_WALLET_CORE env not set");
            return;
        }
        EmailWalletCore core = EmailWalletCore(payable(_core));
        ExtensionHandler extensionHandler = core.extensionHandler();
        vm.startBroadcast(deployerPrivateKey);
        MemoExtension memoExt = new MemoExtension(address(core));
        string memory extensionName = memoExt.extensionName();
        string[][] memory executionTemplates = memoExt.getExecutionTemplates();
        uint256 maxExecutionGas = memoExt.maxExecutionGas();

        extensionHandler.publishExtension(
            extensionName,
            address(memoExt),
            executionTemplates,
            maxExecutionGas
        );
        vm.stopBroadcast();
        console.log("Deployed at %s", address(memoExt));
    }
}
