## Option Tokens

This implements tokenized options on the WETH/USDC pair. Options can be "tethered" to trade with exceptionally high leverage. The MakerDao oracle is used query the spot price for margin calls. This is the brain child of Peter, the friendly 0x research fellow =). This was built as part of the 24h 0x hackathon. _Use at your own risk_ =).

## How it Works - Options

### 1 Begin by defining your option.
```
Option {
    OptionType optionType             = [AMERICAN_CALL | AMERICAN_PUT]
    LibAsset.AssetType makerAsset     = [WETH | USDC]
    LibAsset.AssetType takerAsset     = [USDC | WETH]
    uint256 makerAmount               = [1..10^27]
    uint256 takerAmount               = [1..10^27]
    uint256 expirationTimeInSeconds   = <unix timestamp>
}
```

### 2 Set allowances on the token contract

```
wethToken.approve(address(optionTokenContract), wethToken.totalSupply());
usdcToken.approve(address(optionTokenContract), usdcToken.totalSupply());
```

### 3 Tokenize your option

Mint a maker and taker token for the option. This will also create a unique identifier for your option; this id is a combination of the maker and taker tokens. Initially, both tokens are held by the issuer (you).

```
(bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionTokenContract.tokenize(option);

# EX:
#   optionId     = 0x0000000000000000000000000000000100000000000000000000000000000001
#   makerTokenId = 0x0000000000000000000000000000000100000000000000000000000000000000
#   takerTokenId = 0x0000000000000000000000000000000000000000000000000000000000000001
```

### 4 Fully collateralize your option

This will escrow the maker position in the token contract.

```
optionTokenContract.collateralize(optionId, option, option.makerAmount);
```

### 5 Trade your option (on 0x! :D)

The maker and taker tokens are ERC721 (1155 later) so they can be managed/traded via any platform that supports the standard.
You can choose to sell either the maker or taker positions - or both!

### 6 Exercise the option
When it's time to exercise, whoever holds the `takerTokenId` can exercise the option. This will transfer the escrowed collateral to the taker, and the complementary asset from the taker to the holder of the `makerTokenId`.

```
optionTokenContract.exercise(optionId, option);
```

## How it Works - Synthetic Longs

### 1 Begin by defining two complementary options

```
callOption = {
    optionType: AMERICAN_CALL,
    makerAsset: WETH,
    takerAsset: USDC,
    makerAmount: 1 weth
    takerAmount: 200 usdc
    expirationTimeInSeconds: 1 month
}

putOption = {
    optionType: AMERICAN_PUT,
    makerAsset: USDC,
    takerAsset: ETH,
    makerAmount: 200 usdc
    takerAmount: 1 weth
    expirationTimeInSeconds: 1 month
}
```

### 2 Tokenize the options

```
(bytes32 callOptionId, bytes32 callMakerTokenId, bytes32 callTakerTokenId) = optionTokenContract.tokenize(callOption);
(bytes32 putOptionId, bytes32 putMakerTokenId, bytes32 putTakerTokenId) = optionTokenContract.tokenize(putOption);
```

### 3 Fully collateralize the call option (leave the put option naked)

This will escrow the maker position in the token contract.

```
optionTokenContract.collateralize(optionId, option, option.makerAmount);
```

### 4 Tether the options

Tethering options binds their id's on-chain. Once tethered, the taker cannot exercise the call option until they fully collateralize the put option. 

```
optionTokenContract.tether(callOptionId, callOption, putOptionId, putOption);
```

### 5 Sell the taker token from the call and the maker token from the put option (on 0x!)

### 6 If the underlying asset (weth in this example) nears the margin threshold, the taker may add some collateral w/o fully collateralizing

```
optionTokenContract.collateralize(putOptionId, putOption, <some amount>);
```

### 7 Margin call the taker if the value of the underlying asset drops below the threshold

The contracts can query the ETH/USD price via the MakerDao oracle to validate the call. In this case, any collateral placed in the put option by the taker will go to the maker; their option will be closed and  the tether can be broken.

```
optionTokenContract.marginCall(putOptionId, putOption);
```

### 8 On the flip side -- if the price went up and the taker wished to cash out, they must first fully collateralize the put option

```
optionTokenContract.collateralize(putOptionId, putOption, putOption.makerAmount);
```

### 9 Once collateralized (or margin called) the tether can be broken.

Once untethered, if either or both of the options are still open (not margin called / expired) they can be exercised to realize profits. The issuer (who holds `callMakerTokenId` and `putTakerTokenId`) may realize some profit if there was a margin call, otherwise nil. The counterparty who went long (who holds `callTakerTokenId` and `putMakerTokenId`) can exercise the call option. 

```
optionTokenContract.untether(callOptionId, callOption, putOptionId, putOption);
```


### Install Dependencies

If you don't have yarn workspaces enabled (Yarn < v1.0) - enable them:

```bash
yarn config set workspaces-experimental true
```

Then install dependencies

```bash
yarn install
```

### Build

```bash
yarn build
```

### Clean

```bash
yarn clean
```

### Lint

```bash
yarn lint
```

### Run Tests

```bash
yarn test
```