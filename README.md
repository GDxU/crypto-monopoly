# Crypto Monopoly Game
Crypto Monopoly Game (Smart Contracts)
- ERC20:     Game Token
- ERC721:    NFT Property
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

Console output:
```
ERC20 deployed to: 0xCD50020F9ba2cB98c17FB1b760903aF2a741C911
UserCenter deployed to: 0x5f66A98b9c171356Ab9919db815e8d4055Bc6C4E
House NFT deployed to: 0x00001BbC95694C7502EF08DD5ab8afD1eF7F3d62
House Exchange deployed to: 0x1ed18E93189C7543dbc7543F4d43eD42CF862fa6
Gov deployed to: 0x3634b17AaAedd13E8FaE6b2Ceb6300F4FC8c1F76
Monoploy Game deployed to: 0xd5C9e2FbBcD5893a4eD177Adb9F5f7D3E56f3f3F
setup Monopoly...
Monopoly is ready!
```