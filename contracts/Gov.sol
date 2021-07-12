//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './utils/AdminRole.sol';
import './token/PropertyExchange.sol';
import './token/ERC20Token.sol';

contract Gov is AdminRole {
    PropertyExchange private _pe;
    ERC20Token private _token;

    uint24 public round;

    event Fine(uint8 indexed group, address indexed from, uint16 indexed pos, uint256 value);

    constructor(PropertyExchange pe, ERC20Token token) public {
        _pe = pe;
        _token = token;
    }

    function newRound(uint24 _round) external payable onlyAdmin {
        round = _round;
    }

    function meet(uint16 pos) external pure returns (bool) {
        return (pos == 10 || pos == 30);
    }

    /* type: 1. jail, 2.penalty */
    function fine(
        uint8 group,
        address player,
        address bank,
        uint16 pos,
        uint256 token_penalty
    ) external onlyAdmin {
        _pe.mortgage(player, bank, token_penalty);
        _token.safeTransfer(player, bank, token_penalty);

        emit Fine(group, player, pos, token_penalty);
    }
}
