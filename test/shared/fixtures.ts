import { Wallet, Contract } from 'ethers'
import { Web3Provider } from 'ethers/providers'
import { deployContract } from 'ethereum-waffle'

import { expandTo18Decimals } from './utilities'

// import ERC20 from '../../build/ERC20.json'
import SimpleStorage from '../../build/SimpleStorage.json'

const overrides = {
  gasLimit: 9999999
}

interface V2Fixture {
  // token: Contract
  SimpleStorage: Contract
}

export async function v2Fixture(provider: Web3Provider, [wallet]: Wallet[]): Promise<V2Fixture> {
  // deploy SimpleStorage
  const ss = await deployContract(wallet, SimpleStorage, []) //[expandTo18Decimals(10000)]
  // initialize V1
  // await ss.set(123)

  return {
    SimpleStorage: ss
  }
}
