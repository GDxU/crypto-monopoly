import chai, { expect } from 'chai'
import { Contract } from 'ethers'
import { solidity, MockProvider, deployContract } from 'ethereum-waffle'
import { ether } from './shared/util'

import ERC20Token from '../build/ERC20Token.json'

chai.use(solidity)

const overrides = {
    gasLimit: 9999999,
    gasPrice: 0
}

describe('ERC20Token', () => {
    const provider = new MockProvider({
        ganacheOptions: {
            gasLimit: 9999999
        }
    })
    const [walletDeployer, walletAlice, walletBob] = provider.getWallets()

    let token: Contract

    beforeEach(async () => {
        token = await deployContract(walletDeployer, ERC20Token, [], overrides)
        await token.transfer(walletAlice.address, ether(1000))
    })

    it('Check token balance', async () => {
        expect(await token.balanceOf(walletAlice.address)).to.eq(ether(1000))
    })

    it('Check token symbol', async () => {
        expect(await token.symbol()).to.eq('CHIS')
    })

    it('Check token name', async () => {
        expect(await token.name()).to.eq('Chis Finance')
    })

    it('Transfer adds amount to destination account', async () => {
        await token.connect(walletAlice).transfer(walletBob.address, ether(10))
        expect(await token.balanceOf(walletBob.address)).to.eq(ether(10))
    })

    it('Transfer emits event', async () => {
        await expect(token.connect(walletAlice).transfer(walletBob.address, 100))
            .to.emit(token, 'Transfer')
            .withArgs(walletAlice.address, walletBob.address, 100)
    })

    it('Can not transfer above the amount', async () => {
        await expect(token.connect(walletAlice).transfer(walletBob.address, ether(1001))).to.be.reverted
    })

    it('Can not transfer from empty account', async () => {
        await expect(token.connect(walletBob).transfer(walletAlice.address, 1)).to.be.reverted
    })

    it('Calls totalSupply on Token contract', async () => {
        await token.totalSupply()
        expect('totalSupply').to.be.calledOnContract(token)
    })

    it('Calls balanceOf with sender address on Token contract', async () => {
        await token.balanceOf(walletAlice.address)
        expect('balanceOf').to.be.calledOnContractWith(token, [walletAlice.address])
    })
})
