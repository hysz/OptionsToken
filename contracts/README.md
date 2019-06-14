This is how I’m thinking about it. Lmk what you think (or we can chat about it when I get in at 1:15).

As a margin maker, I create two options:
```
### 1 an american call option
makerCallOption = {
    optionType: AMERICAN_CALL
    makerAmount: 1 ETH
    takerAmount: 200 USD
    collateralizationTolerance: 0
    expiration: 1y
    salt: <some random value>
}

### 2 a european put option
takerPutOption = {
    optionType: EUROPEAN_PUT
    makerAmount: 200 USD
    takerAmount: 1 ETH
    collateralizationTolerance: 0.1
    expiration: 1y
    salt: <some random value>
}
```

The margin maker now does two things:
1. Executes on-chain OptionToken.tether(makerCallOption, takerPutOption). This does 3 things:
   1. collateralizes the call option
   2. sets the creator as taker of the put option
   3. sets state such that in order for the call option to be exercised, the taker must fully collateralize the put option.
2. The maker sells the tethered options. The identifier is <hash(makerCAllOption)><hash(takerPutOption)>.
   The Launchkit does not support ERC1155 so we're using ERC721 identifiers, which can be be at most 256-bits.
   To achieve this for the hackathon, we create 128-bit hashes by truncating the regular hash function.




Example:

ETH is $150.

Call Option is 1 ETH / $100. Put option is $100 / 1 ETH.

Margin Trigger on Put option is $125. I sell the call option for $50.

I place 1 ETH into escrow.




At any time, Bob can buy the 1 ETH for $100, so long as he collateralizes the Put option with $100.

