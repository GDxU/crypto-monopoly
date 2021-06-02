import chai, { expect } from 'chai'
import { Contract } from 'ethers'
import { solidity, MockProvider, deployContract } from 'ethereum-waffle'
import { BigNumber } from 'ethers'

import PropertyOwnership from '../build/PropertyOwnership.json'

chai.use(solidity)

const overrides = {
    gasLimit: 9999999,
    gasPrice: 0
}

describe('NFT', () => {
    const provider = new MockProvider({
        ganacheOptions: {
            gasLimit: 9999999
        }
    })
    const [walletDeployer, walletAlice, walletBob] = provider.getWallets()

    const blackholeAddress = '0x0000000000000000000000000000000000000000'
    let nft: Contract

    beforeEach(async () => {    
        nft = await deployContract(walletDeployer, PropertyOwnership, [], overrides)
    })

    const mint = async (toAddress: string, nftId: number) => {
        // mint: from address 0x0 
        await nft.transfer(blackholeAddress, toAddress, nftId)
    }

    it('Check nft init balance', async () => {
        expect(await nft.balanceOf(walletAlice.address)).to.eq(0)
    })

    it('Check nft balance after mint', async () => {
        await mint(walletAlice.address, 1)
        expect(await nft.balanceOf(walletAlice.address)).to.eq(1)
    })

    it('Check nft symbol', async () => {
        expect(await nft.symbol()).to.eq('MON')
    })

    it('Check nft name', async () => {
        expect(await nft.name()).to.eq('MONOPOLY')
    })

    it('Transfer from Alice to Bob', async () => {
        await mint(walletAlice.address, 1)
        expect(await nft.balanceOf(walletBob.address)).to.eq(0)
        await nft.transfer(walletAlice.address, walletBob.address, 1)
        expect(await nft.balanceOf(walletBob.address)).to.eq(1)
    })

    it('Transfer emits event', async () => {
        await mint(walletAlice.address, 1)
        await expect(nft.transfer(walletAlice.address, walletBob.address, 1))
        .to.emit(nft, 'Transfer')
        .withArgs(walletAlice.address, walletBob.address, 1)
    })

    it('Can not transfer above the amount', async () => {
        await mint(walletAlice.address, 1)
        await expect(nft.connect(walletAlice).transfer(walletBob.address, 2)).to.be.reverted
    })

    it('Can not transfer from empty account', async () => {
        await expect(nft.connect(walletBob).transfer(walletAlice.address, 1)).to.be.reverted
    })

    it('Calls totalSupply on nft contract', async () => {
        await nft.totalSupply()
        expect('totalSupply').to.be.calledOnContract(nft)
    })

    it('Calls balanceOf with sender address on nft contract', async () => {
        await nft.balanceOf(walletAlice.address)
        expect('balanceOf').to.be.calledOnContractWith(nft, [walletAlice.address])
    })

    it('Approve to tranfer from Alice to Bob', async () => {
        await mint(walletAlice.address, 1)
        await nft.connect(walletAlice).approve(walletBob.address, 1)
        await nft.connect(walletBob).transferFrom(walletAlice.address, walletBob.address, 1)
        expect(await nft.ownerOf(1)).to.eq(walletBob.address)
    })

    it('Calls ownerOf with Alice', async () => {
        await mint(walletAlice.address, 1)
        expect(await nft.ownerOf(1)).to.eq(walletAlice.address)
    })

    it('Calls tokensOfOwner with Alice', async () => {
        await mint(walletAlice.address, 1)
        await mint(walletBob.address, 2)
        await mint(walletAlice.address, 3)
        const tokensOfAlice = (await nft.tokensOfOwner(walletAlice.address)).map((x:BigNumber) => x.toNumber())
        const tokensOfBob = (await nft.tokensOfOwner(walletBob.address)).map((x:BigNumber) => x.toNumber())
        expect(tokensOfAlice).to.have.ordered.members([1,3])
        expect(tokensOfBob).to.have.ordered.members([2])
    })

})
