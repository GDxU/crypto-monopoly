import chai, { expect } from 'chai'
import { Contract, Wallet } from 'ethers'
import { solidity, MockProvider, deployContract, deployMockContract } from 'ethereum-waffle'
import { ether } from './shared/util'

import ERC20Token from '../build/ERC20Token.json'
import PropertyExchange from '../build/PropertyExchange.json'
import Gov from '../build/Gov.json'

chai.use(solidity)

const overrides = {
    gasLimit: 9999999,
    gasPrice: 0
}

describe('Gov', () => {
    const provider = new MockProvider({
        ganacheOptions: {
            gasLimit: 9999999
        }
    })

    const [walletDeployer, walletAlice, walletBob, walletBank] = provider.getWallets()

    let propertyExchange: Contract
    let token: Contract
    let gov: Contract

    beforeEach(async () => {
        propertyExchange = await deployMockContract(walletDeployer, PropertyExchange.abi)
        token = await deployMockContract(walletDeployer, ERC20Token.abi)
        gov = await deployContract(walletDeployer, Gov, [propertyExchange.address, token.address], overrides)
    })

    it('New round', async () => {
        await gov.newRound(2)
        expect(await gov.round()).to.eq(2)
    })

    it('Meet position', async () => {
        expect(await gov.meet(0)).to.eq(false)
        expect(await gov.meet(10)).to.eq(true)
        expect(await gov.meet(20)).to.eq(false)
        expect(await gov.meet(30)).to.eq(true)
    })

    it('Fine emits event', async () => {
        await propertyExchange.mock.mortgage.withArgs(walletAlice.address, walletBank.address, ether(100)).returns()
        await token.mock.safeTransfer.withArgs(walletAlice.address, walletBank.address, ether(100)).returns(true)
        await expect(gov.fine(1, walletAlice.address, walletBank.address, 2, ether(100))).to.emit(gov, 'Fine')
    })

    it('Fine reverts', async () => {
        await propertyExchange.mock.mortgage.withArgs(walletAlice.address, walletBank.address, ether(10000)).reverts()
        await token.mock.safeTransfer.withArgs(walletAlice.address, walletBank.address, ether(10000)).reverts()
        await expect(gov.fine(1, walletAlice.address, walletBank.address, 2, ether(10000))).to.be.reverted
    })
})
