import chai, { expect } from 'chai'
import { Contract } from 'ethers'
import { solidity, MockProvider, deployContract } from 'ethereum-waffle'
import { ether, toEther } from './shared/util'

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
    const [wallet, walletTo] = provider.getWallets()

    let token: Contract

    beforeEach(async () => {    
        token = await deployContract(wallet, ERC20Token, [], overrides)
    })

    it('Assigns initial balance', async () => {
        expect(await token.balanceOf(wallet.address)).to.equal(ether(1000));
      });
    
      it('Transfer adds amount to destination account', async () => {
        await token.transfer(walletTo.address, 7);
        expect(await token.balanceOf(walletTo.address)).to.equal(7);
      });
    
      it('Transfer emits event', async () => {
        await expect(token.transfer(walletTo.address, 7))
          .to.emit(token, 'Transfer')
          .withArgs(wallet.address, walletTo.address, 7);
      });
    
      it('Can not transfer above the amount', async () => {
        await expect(token.transfer(walletTo.address, ether(1001))).to.be.reverted;
      });
    
      it('Can not transfer from empty account', async () => {
        const tokenFromOtherWallet = token.connect(walletTo);
        await expect(tokenFromOtherWallet.transfer(wallet.address, 1))
          .to.be.reverted;
      });
    
      it('Calls totalSupply on BasicToken contract', async () => {
        await token.totalSupply();
        expect('totalSupply').to.be.calledOnContract(token);
      });
    
      it('Calls balanceOf with sender address on BasicToken contract', async () => {
        await token.balanceOf(wallet.address);
        expect('balanceOf').to.be.calledOnContractWith(token, [wallet.address]);
      });

})
