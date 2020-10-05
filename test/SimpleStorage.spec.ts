import chai, { expect } from 'chai'
import { Contract, BigNumber } from 'ethers'
// import { MaxUint256 } from 'ethers/constants'
// import { defaultAbiCoder, formatEther } from 'ethers/lib/utils'
import { solidity, MockProvider, createFixtureLoader, deployContract } from 'ethereum-waffle'

// import { expandTo18Decimals } from './shared/utilities'
// import { v2Fixture } from './shared/fixtures'

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
  // const loadFixture = createFixtureLoader(provider, [wallet])

  let ss: Contract
  beforeEach(async function () {
    // const fixture = await loadFixture(v2Fixture)

    // ss = fixture.SimpleStorage
    ss = await deployContract(
      wallet,
      SimpleStorage,
      [],
      overrides
    )
  })

  it('set:123', async () => {
    // const ethAmount = expandTo18Decimals(10)
    await ss.set(BigNumber.from(123))
    // await ss.set(bigNumberify(1), {
    //   ...overrides,
    //   value: ethAmount
    // })

    const value = await ss.get()
    expect(value.toString()).to.eq('123')
  })

})
