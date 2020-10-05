import chai, { expect } from 'chai'
import { Contract, BigNumber } from 'ethers'
import { solidity, MockProvider, deployContract } from 'ethereum-waffle'

import SimpleStorage from '../build/SimpleStorage.json'

chai.use(solidity)

const overrides = {
  gasLimit: 9999999,
  gasPrice: 0
}

describe('SimpleStorageTest', () => {
  const provider = new MockProvider({
    ganacheOptions: {
      gasLimit: 9999999
    }
  })
  const [wallet] = provider.getWallets()

  let ss: Contract
  beforeEach(async function () {
    ss = await deployContract(
      wallet,
      SimpleStorage,
      [],
      overrides
    )
  })

  it('set:123', async () => {
    await ss.set(BigNumber.from(123))
    const value = await ss.get()
    expect(value.toString()).to.eq('123')
  })

})
