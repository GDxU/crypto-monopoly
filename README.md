# Chis Finance
Chis Finance (Smart Contracts)
- ERC20:     Chis Token
- Solidity:  ^0.6.6
- Tool:      ethereum-waffle
- UnitTest:  TypeScript + mocha + chai
- Deploy:    hardhat + alchemyapi

# Local Development

The following assumes the use of `node@>=10`.

## Install Dependencies

`yarn`

## Compile Contracts

`yarn compile`

## Run Tests

`yarn test`


## Integration Tests

`yarn test-integration`

## Deploy to Testnet

```
export ROPSTEN_PRIVATE_KEY=<Your private key>
npx hardhat run scripts/deploy.js --network ropsten
```
or
`yarn deploy`