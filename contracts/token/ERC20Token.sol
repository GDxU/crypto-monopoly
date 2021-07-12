//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';
import '../utils/AdminRole.sol';

/**
 * @title ERC20Token
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract ERC20Token is ERC20, AdminRole {
    uint256 private constant INITIAL_SUPPLY = 10**18 * (10**18);
    constructor() public ERC20('Chis Finance', 'CHIS') {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
