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

describe('MonopolyTest', () => {
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
        console.info(`${deployer}: ${await wallet.getBalance()}`)

        // const deployerOptions = { ...overrides, from: await wallet.getAddress() }

        token = await deployContract(wallet, ERC20Token, [], overrides)
        console.info(`"Token": "${token.address}",`)
        uc = await deployContract(wallet, UserCenter, [], overrides)
        console.info(`"UserCenter": "${uc.address}",`)
        po = await deployContract(wallet, PropertyOwnership, [], overrides)
        console.info(`"PropertyOwnership": "${po.address}",`)
        pe = await deployContract(wallet, PropertyExchange, [po.address, token.address], overrides)
        console.info(`"PropertyExchange": "${pe.address}",`)
        gov = await deployContract(wallet, Gov, [pe.address, token.address], overrides)
        console.info(`"Gov": "${gov.address}",`)
        game = await deployContract(wallet, Game, [], overrides)
        console.info(`"Game": "${game.address}"`)
        await game.setMaxNumberOfMove(50)
        console.info(`setMaxNumberOfMove 50`)

        await uc.addAdmin(game.address)
        console.info(`init uc.`)
        await token.addAdmin(pe.address)
        await token.addAdmin(gov.address)
        await token.addAdmin(game.address)
        console.info(`init token.`)
        await po.addAdmin(pe.address)
        await po.addAdmin(game.address)
        await pe.addAdmin(gov.address)
        await pe.addAdmin(game.address)
        await gov.addAdmin(game.address)
        await game.setup(po.address, pe.address, token.address, uc.address, gov.address)
        console.info(`init game.`)
    })

    const balOf = async (_account: string) => {
        return await token.balanceOf(_account)
    }

    const balEther = async (_account: string) => {
        return toEther(await token.balanceOf(_account))
    }

    let num = 0
    const move = async (_account: string, r1: number, r2: number, msg: string) => {
        const moveOptions = { ...overrides }
        const playerWallect = wallets[_account]
        let round = await game.round()
        console.info(`***************** #${num} round=${round}, (${msg} move and buy)**********************`)
        let pos = await uc.getPos(_account, round)
        console.info(`from pos: ${pos}`)
        //await game.connect(playerWallect).moveTo(r1, r2, moveOptions)
        await game.connect(playerWallect).move(moveOptions)
        round = await game.round()
        pos = await uc.getPos(_account, round)
        console.info(`to pos: ${pos}`)
        if ((await game.connect(playerWallect).canBuy(pos, moveOptions)) && (await balOf(_account)).gt(0)) {
            console.info(`pos: ${pos}, can buy!`)
            try {
                await game.connect(playerWallect).buy(moveOptions)
            } catch (err) {
                console.info(`********* buy error :${err} ********`)
            }
            console.info(
                `pos: ${pos}, buy price: ${await pe.buyPrice(
                    pos
                )},avg: ${await pe.avgPrice()}, new:${await pe.getNewestPrice(pos)}  rent: ${await pe.rentPrice(pos)}`
            )

            //console.info(`all houses[pos]   🏡🏡 [${await pe.getPropertyPositions(round)}] 🏡🏡`);
            //console.info(`all houses[index] 🏡🏡 [${await game.getPropertyIndexes(round)}] 🏡🏡`);
            console.info(`all houses[pe]    🏡🏡 [${await pe.getPropertyIndexes(round)}] 🏡🏡`)
            //console.info(`${msg} first house id: ${await po.balOfOwnerByIndex(_account, 0)}`);
            //console.info(`number of house: ${await po.balanceOf(_account)}`);|| ${await po.tokensOfOwner(_account)}
            console.info(`${msg} houses:  ${await pe.getProperties(_account)} `)

            const res = await game.getWinner()
            // console.info(`res---------------\n`, res)
            const [winner, num, fund, total] = await game.getWinner()
            console.info(
                `round=${await game.round()}, winner: ${winner}, num: ${num}, fund: ${fund}, total: ${toEther(total)}`
            )
        } else {
            console.info(`********* cannot buy ${pos}********`)
        }

        console.info(`p0: ${await balEther(investor)}, p1: ${await balEther(player1)}, p2: ${await balEther(player2)}`) //, poorman: ${(await balOf(poorman))}

        const totalAmount = (await balOf(investor))
            .add(await balOf(player1))
            .add(await balOf(player2))
            .add(await game.bonusPool())

        console.info(
            `game balance: ${await balEther(game.address)}, ${toEther(await game.bonusPool())} , total: ${toEther(
                totalAmount
            )}}`
        )

        num++
    }

    it('get maxNumberOfMove', async () => {
        const value = await game.maxNumberOfMove()
        expect(value.toString()).to.eq('50')
    })

    it('move test', async () => {
        await token.transfer(investor, ether(1000), { from: deployer })
        await token.transfer(player1, ether(1000), { from: deployer })
        await token.transfer(player2, ether(1000), { from: deployer })
        console.info(`p0 balance: ${await balEther(investor)}`)
        console.info(`p1 balance: ${await balEther(player1)}`)
        console.info(`p2 balance: ${await balEther(player2)}`)
        console.info(`game balance: ${await balEther(game.address)}`)
        await token.transfer(game.address, ether(9999), { from: deployer })
        console.info(`game balance: ${await balEther(game.address)}`)
        const value = await balOf(game.address)
        expect(value).to.eq(ether(9999))

        let i = 0
        while (i++ < 100) {
            await move(investor, 1, 2, 'p0')
            await move(player1, 1, 2, 'p1')
            await move(player2, 1, 2, 'p2')
            console.info(`****************** NEXT ${i} *********************`)
        }
    })

    afterEach(async () => {
        console.info('***************************************')
    })
})
