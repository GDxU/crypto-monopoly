import chai, { expect } from 'chai'
import { Contract, Wallet } from 'ethers'
import { solidity, MockProvider, deployContract } from 'ethereum-waffle'
import { ether, toEther } from './shared/util'

import Game from '../build/Game.json'
import ERC20Token from '../build/ERC20Token.json'
import UserCenter from '../build/UserCenter.json'
import PropertyOwnership from '../build/PropertyOwnership.json'
import PropertyExchange from '../build/PropertyExchange.json'
import Gov from '../build/Gov.json'

chai.use(solidity)

const overrides = {
    gasLimit: 9999999,
    gasPrice: 0
}

describe('Monopoly UnitTest', () => {
    const provider = new MockProvider({
        ganacheOptions: {
            gasLimit: 9999999
        }
    })

    const [walletDeployer, walletPlayer] = provider.getWallets()

    let game: Contract
    let token: Contract
    let uc: Contract
    let nft: Contract
    let pe: Contract
    let gov: Contract

    beforeEach(async () => {        
        // deploy the Monopoly game
        token = await deployContract(walletDeployer, ERC20Token, [], overrides)
        uc = await deployContract(walletDeployer, UserCenter, [], overrides)
        nft = await deployContract(walletDeployer, PropertyOwnership, [], overrides)
        pe = await deployContract(walletDeployer, PropertyExchange, [nft.address, token.address], overrides)
        gov = await deployContract(walletDeployer, Gov, [pe.address, token.address], overrides)
        game = await deployContract(walletDeployer, Game, [], overrides)
        
        // initialize the Monopoly game
        await uc.addAdmin(game.address)
        await token.addAdmin(pe.address)
        await token.addAdmin(gov.address)
        await token.addAdmin(game.address)
        await nft.addAdmin(pe.address)
        await nft.addAdmin(game.address)
        await pe.addAdmin(gov.address)
        await pe.addAdmin(game.address)
        await gov.addAdmin(game.address)
        await game.setup(nft.address, pe.address, token.address, uc.address, gov.address)

    })

    it('Calls maxNumberOfMove', async () => {
        await game.setMaxNumberOfMove(50)
        expect(await game.maxNumberOfMove()).to.eq(50)
    })

    it('Calls round', async () => { 
        expect(await game.round()).to.eq(1)
    })

    it('Move and check the position', async () =>{
        await token.transfer(walletPlayer.address, ether(1000))
        await game.connect(walletPlayer).move(overrides)
        const pos = await uc.getPos(walletPlayer.address, 1)
        expect(pos).to.greaterThanOrEqual(2)
        expect(pos).to.lessThanOrEqual(12)
    })

})
