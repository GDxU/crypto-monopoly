pragma solidity =0.6.6;

import './libraries/AdminRole.sol';
import './PropertyExchange.sol';

contract Gov is AdminRole {
    //mapping(uint24 => mapping(address => bool)) private jailStatus; // round => player address => inJail

    PropertyExchange private _pe;
    YopoToken private _token;

    uint24 public round;

    event Fine(uint8 indexed group, address indexed from, uint16 indexed pos, uint256 value);

    constructor(PropertyExchange pe, YopoToken token) public {
        _pe = pe;
        _token = token;
    }

    function newRound(uint24 _round) external payable onlyAdmin {
        round = _round;
    }

    //    function getJailedStatus(address _player) external view returns (bool) {
    //        return jailStatus[round][_player];
    //    }
    //
    //    function inPrison(address _player) external payable onlyAdmin {
    //        jailStatus[round][_player] = true;
    //    }
    //
    //    function free(address _player) external payable onlyAdmin {
    //        jailStatus[round][_player] = false;
    //    }

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
        //uint256 token_penalty = _pe.price2Token(penalty_fee);
        _pe.mortgage(player, bank, token_penalty);

        _token.safeTransfer(player, bank, token_penalty);
        emit Fine(group, player, pos, token_penalty);
    }
}
