
# Email Wallet Extensions Guide

The Email Wallet SDK comprises smart contracts that enhance an email wallet's functionality. This SDK enables the creation of custom extensions that can interact with any smart contracts. It supports operations like token swapping via Uniswap, NFT transfer from the email wallet, and more. Third-party developers can build new functionality of email wallet using our SDK for extensions.

## Setup

To create an extension using the Email Wallet SDK, follow these steps:

1. **Create a new repository**: Start by creating a new repository using our template in the repo.

2. **Clone the repository**: Once the repository is created, clone it to your local machine.

3. **Install dependencies**: Navigate to the cloned folder and execute yarn to install the necessary dependencies.

## Modify MomoExtension.sol 

After setting up the repository, the next step is to modify the `src/MemoExtension.sol` contract for your own implementation.

1. **Rename the contract**: Rename the src/MemoExtension.sol to any name that suits your extension.

2. **Create your own extension implementation**:

MomoExtension.sol is an example of the extension implementation. Each developer will need to implement actual functionality using the interface as a guide.

These functions **MUST** be included in your contract.

**`execute(uint8 templateIndex, bytes[] subjectParams, address wallet, bool hasEmailRecipient, address recipientETHAddr, bytes32 emailNullifier) external virtual`**

- **Description**: Executes the extension logic based on specific parameters derived from the email subject.
- **Parameters**:
    - `templateIndex`: Index of the subject template to which the subject was matched.
    - `subjectParams`: Array of parameters decoded from the email subject based on the template, in the same order as the matchers.
    - `wallet`: Address of the user’s wallet.
    - `hasEmailRecipient`: A flag indicating whether the email subject has an email address recipient.
    - `recipientETHAddr`: The ETH address of the recipient in the email when `hasEmailRecipient` is `false`.
    - `emailNullifier`: Nullifier of the email.
- **Notes**:
    - It is recommended to send tokens to the sender’s wallet by calling `EmailWalletCore.depositTokenToAccount` rather than directly calling `transfer` of the erc20 token. They have no different in our current spec, but it can be not true in the future spec.
    - The `{tokenAmount}` parameter in the template should be decoded using `abi.decode(uint256, string)` to extract `tokenName` and `tokenAmount`.

### `registerUnclaimedState(UnclaimedState memory unclaimedState, bool isInternal) public virtual`

- **Description**: Registers an unclaimed state for a recipient email commitment.
- **Parameters**:
    - `unclaimedState`: Unclaimed state that is being registered.
    - `isInternal`: A flag indicating whether the unclaimed state is registered from `registerUnclaimedStateAsExtension`.
- **Default Implementation:** return a revert error.

### `claimUnclaimedState(UnclaimedState memory unclaimedState, address wallet) external virtual`

- **Description**: Claims an unclaimed state for a recipient user.
- **Parameters**:
    - `unclaimedState`: Unclaimed state that is being claimed.
    - `wallet`: Address of the user’s wallet.
- **Default Implementation:** return a revert error.

### `voidUnclaimedState(UnclaimedState memory unclaimedState) external virtual`

- **Description**: Reverts an expired unclaimed state.
- **Parameters**:
    - `unclaimedState`: Unclaimed state that has expired.
- **Default Implementation:** return a revert error.

3. **Define Subject Templates**:
Subject templates are an array of string arrays, i.e., a two-dimensional string array. These are defined by an extension to declare the formats of the subject that will call the extension. Each format can use a fixed string (without spaces) and the following templates.

- `"{tokenAmount}"`: a combination of the decimal string of the token amount and the string of the token name. The corresponding parameter in `subjectParams` is the bytes encoding `(uint256,string)`. The decimal size of the amount depends on the `decimals` value of the ERC20 contract of the token name. For example, “1.5 ETH” ⇒ `abi.encode((1.5 * (10**18), "ETH"))`, “3.4 USDC” ⇒ `abi.encode((3.4 * (10**6), "USDC"))`.
- `"{amount}"`: a decimal string. The corresponding parameter in `subjectParams` is the bytes encoding `uint256`. The decimal size of the amount is fixed to 18. For example, “2.7” ⇒ `abi.encode(2.7 * (10**18))`.
- `"{string}"`: a string. The corresponding parameter in `subjectParams` is the bytes encoding `string`.
- `"{uint}"`: a decimal string of the unsigned integer. The corresponding parameter in `subjectParams` is the bytes encoding `uint256`.
- `"{int}"`: a decimal string of the signed integer. The corresponding parameter in `subjectParams` is the bytes encoding `int256`.
- `"{address}"`: a hex string of the Ethereum address. The corresponding parameter in `subjectParams` is the bytes encoding `address`.
- `"{recipient}"`: either the recipient’s email address or a hex string of the recipient’s Ethereum address. The corresponding parameter in `subjectParams` is the bytes encoding either `uint256` of the byte size of the email address or `address` of the Ethereum address.

4. **Compile the Contract**: Compile the contract by running:
```
$ forge build
```

## Modify the Test Codes
After modifying the extension contract, the next step is to modify the test codes.

1. Rename the test file: Rename the test/MemoExtension.t.sol to any name that suits your extension.

2. Modify the test codes: Update the test codes to test the functionality of your extension.

3. Run the tests: You can run the tests by running 
```
$ forge test
```
## Publish the Extension
To publish your extension to our email wallet core contract, run the following command:

```
    PRIVATE_KEY=0x... EMAIL_WALLET_CORE=0x7A07f282Ebdc033da00EC46D602eCE742825C6dB forge script script/Deploy.s.sol --rpc-url https://arb1.arbitrum.io/rpc --chain-id 42161 --broadcast
```

Note: PRIVATE_KEY is the hex string of the private key used for the deployment.


