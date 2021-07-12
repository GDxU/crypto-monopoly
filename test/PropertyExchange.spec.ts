import chai, { expect } from 'chai'
import { Contract, Wallet } from 'ethers'
import { solidity, MockProvider, deployContract, deployMockContract } from 'ethereum-waffle'
import { ether } from './shared/util'
import { BigNumber } from 'ethers'

import ERC20Token from '../build/ERC20Token.json'
import PropertyOwnership from '../build/PropertyOwnership.json'
import PropertyExchange from '../build/PropertyExchange.json'

chai.use(solidity)

const overrides = {
    gasLimit: 9999999,
    gasPrice: 0
}

describe('PropertyExchange', () => {
    const provider = new MockProvider({
        ganacheOptions: {
            gasLimit: 9999999
        }
    })

    const [walletDeployer, walletAlice, walletBob, walletBank] = provider.getWallets()

    let token: Contract
    let nft: Contract
    let propertyExchange: Contract

    beforeEach(async () => {
        token = await deployMockContract(walletDeployer, ERC20Token.abi)
        nft = await deployMockContract(walletDeployer, PropertyOwnership.abi)
        propertyExchange = await deployContract(
            walletDeployer,
            PropertyExchange,
            [nft.address, token.address],
            overrides
        )
    })

    it('New round and house avg price', async () => {
        await propertyExchange.newRound(1, 10)
        expect(await propertyExchange.round()).to.eq(1)
        expect(await propertyExchange.avgPrice()).to.eq(10)
    })

    it('Buy a house', async () => {
        await token.mock.balanceOf.withArgs(walletAlice.address).returns(ether(1000))
        await nft.mock.transfer.returns()
        await nft.mock.ownerOf.returns(walletBob.address)
        expect(await propertyExchange.hasProperty(1)).to.eq(false)
        await propertyExchange.buy(walletAlice.address, 1, 10)
        expect(await propertyExchange.hasProperty(1)).to.eq(true)
    })

    it('Mortgage: Bankrupt emits event', async () => {
        await token.mock.balanceOf.withArgs(walletAlice.address).returns(ether(1000))
        await nft.mock.tokensOfOwner.returns([])
        await expect(propertyExchange.mortgage(walletAlice.address, walletBank.address, ether(1001))).to.emit(
            propertyExchange,
            'Bankrupt'
        )
    })
})
