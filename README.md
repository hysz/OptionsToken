## Option Tokens

This implements tokenized options on the WETH/USDC pair. Options can be "tethered" to trade with exceptionally high leverage. The MakerDao price oracle is used query a spot price for margin calls. This is the brain child of Peter, the friendly 0x research fellow =). This was built as part of the 24h 0x hackathon. _Use at your own risk_ =).

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