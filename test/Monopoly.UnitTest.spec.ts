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
    /* accounts: [{ balance: 'BALANCE IN WEI', secretKey: 'PRIVATE KEY' }] */

    const [wallet, p0, p1, p2] = provider.getWallets()

    const deployer = wallet.address
    const investor = p0.address
    const player1 = p1.address
    const player2 = p2.address
    const wallets: Record<string, Wallet> = {}
    for (const w of [wallet, p0, p1, p2]) {
        wallets[w.address] = w
    }

    let game: Contract
    let token: Contract
    let uc: Contract
    let po: Contract
    let pe: Contract
    let gov: Contract

    beforeEach(async () => {        
        console.info(`deploying the Monopoly game...`)

        token = await deployContract(wallet, ERC20Token, [], overrides)
        uc = await deployContract(wallet, UserCenter, [], overrides)
        po = await deployContract(wallet, PropertyOwnership, [], overrides)
        pe = await deployContract(wallet, PropertyExchange, [po.address, token.address], overrides)
        gov = await deployContract(wallet, Gov, [pe.address, token.address], overrides)
        game = await deployContract(wallet, Game, [], overrides)
        
        console.info(`initializing the Monopoly game...`)

        await uc.addAdmin(game.address)
        await token.addAdmin(pe.address)
        await token.addAdmin(gov.address)
        await token.addAdmin(game.address)
        await po.addAdmin(pe.address)
        await po.addAdmin(game.address)
        await pe.addAdmin(gov.address)
        await pe.addAdmin(game.address)
        await gov.addAdmin(game.address)
        await game.setup(po.address, pe.address, token.address, uc.address, gov.address)

        console.info(`Monopoly game is ready!`)
    })

    it('test maxNumberOfMove', async () => {
        await game.setMaxNumberOfMove(50)
        const value = await game.maxNumberOfMove()
        expect(value.toString()).to.eq('50')
    })

})
