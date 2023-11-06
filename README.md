# Email-Wallet SDK
The Email Wallet SDK is a set of smart contracts designed to provide functionalities for an Ethereum-based application. The main feature of this SDK is the handling of commands, which are messages or notes associated with transactions or other operations within the system.

## Main Components

### ExtensionBase.sol
This is a contract that provides structure for defining and managing extensions. Extensions are used to call other smart contracts and trigger specific actions.

### ExtensionQuery.sol

This is an abstract contract that provides a structure for defining and managing query templates. These templates are used to parse the subject line of an email into a format understood by the smart contract.

THe `defineQueryTemplate` function is used to define the actual query templates and the query function is used to execute the query.

### StringUtils.sol
This library provides various utility functions for string manipulation.

### MemoExtension.sol
This is an example of an extension contract.

## Create your Own Extension with our Email-Wallet SDK

### Installation

To install our SDK run:
```bash
yarn add email-wallet-sdk
```
### Step 1: Inherit the ExtensionBase Contract
Your extension contract should inherit from the ExtensionBase
```js
import {ExtensionBase} from "./helpers/ExtensionBase.sol";

contract MyExtension is ExtensionBase {
    // Your extension code goes here
}
```
### Step 2: Define Execution Templates
Execution templates structure the email subject input to activate your extension. They are used to parse the subject line of an email into a format thats understandable by a smart contract.

```js
function defineExecutionTemplates()
    internal
    pure
    override
    returns (string[] memory)
{
    // Define your execution templates here
}
```
When defining your own execution template, you should follow this format:

1. **Command**: This is the first word in the template and it represents the action to be performed. Examples of command words could be swap, send, transfer, withdraw, or anything you want it to be.

2. **Placeholders**: Enclosed in curly braces {} these represent the dynamic parts of the subject line. The placeholder should describe the type of input thats expected. For example, {string} is used for a string input, {recipient} is used for the recipients address, and {tokenAmount} for the amount of tokens to be transferred. 

Here are some examples of execution templates:
- Transfer {tokenAmount} to {recipient}
- Vote {proposalId}
- Swap from {tokenAddr} to {tokenAddr}

### Step 3: Implement the execute function
The execute function implements the logic for executing a template based on the provided templateIndex and subject parameters.
```js
 function execute(
        uint8 templateIndex,
        bytes[] memory subjectParams,
        address wallet,
        bool hasEmailRecipient,
        address recipientETHAddr,
        bytes32 emailNullifier
    ) {
        // Insert execution logic here
    }
```

Here's a general breakdown of the function:

- **templateIndex**: This is the index of the execution template that matches the format of the email subject line.
- **subjectParams**: This is an array of bytes that represents the parsed subject line of the email. Each element corresponds to a placeholder in the execution template.
- **wallet**: This is the address of the wallet that is executing the action.
- **hasEmailRecipient**: This is a boolean indicating whether the email has a recipient.
- **recipientETHAddr**: If hasEmailRecipient is true, this is the Ethereum address of the email recipient.
- **emailNullifier**: This is a unique identifier for the email to prevent double-spending.

## Step 4: Implement State Management Functions
In some cases, your extension might need to manage state that is not immediately claimed or that can be voided. For this, you can implement functions like registerUnclaimedState, claimUnclaimedState, and voidUnclaimedState.

These functions should validate the state, update the necessary state variables, and perform any necessary actions (like transferring tokens).

## Step 5: Deploy and Register Your Extension



