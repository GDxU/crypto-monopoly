import chai, { expect } from 'chai'
import { Contract, Wallet } from 'ethers'
import { solidity, MockProvider, deployContract } from 'ethereum-waffle'

import UserCenter from '../build/UserCenter.json'

chai.use(solidity)

const overrides = {
    gasLimit: 9999999,
    gasPrice: 0
}

describe('UserCenter', () => {
    const provider = new MockProvider({
        ganacheOptions: {
            gasLimit: 9999999
        }
    })

    const [walletDeployer, walletAlice, walletBob] = provider.getWallets()

    let uc: Contract

    beforeEach(async () => {     
        uc = await deployContract(walletDeployer, UserCenter, [], overrides)
    })

    it('Register a new user', async () => {
        await uc.register(walletAlice.address) 
        expect(await uc.totalUsers()).to.eq(1)
    })

    it('Register emits event', async () => { 
        await expect(uc.register(walletAlice.address) )
        .to.emit(uc, 'UserRegistered');
    })

    it('Check if a user exists', async () => {
        await uc.register(walletAlice.address) 
        expect(await uc.exists(walletAlice.address)).to.eq(true)
        expect(await uc.exists(walletBob.address)).to.eq(false)
    })

})
