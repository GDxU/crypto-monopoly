//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './ERC20Token.sol';
import '../utils/AdminRole.sol';

contract ERC20Referral is AdminRole {
    using SafeMath for uint256;
    ERC20Token private _token;
    uint16 private _referral_rate = 5;
    bool private _promo = true;
    mapping(address => address) private _referral_map;
    mapping(address => uint256) private _airdrop_map;

    event TokensReferral(address indexed to, uint256 value);

    constructor(ERC20Token token) public {
        _token = token;
    }

    /**
     * @return the amount of referral rate.
     */
    function referral_rate() public view returns (uint16) {
        return _referral_rate;
    }

    /**
     * @return if promotion enabled.
     */
    function promotion() public view returns (bool) {
        return _promo;
    }

    /**
     * set referral rate & promo.
     */
    function set_referral(uint16 rate, bool promo) public payable onlyAdmin {
        if (rate > 0) {
            _referral_rate = rate;
        }
        _promo = promo;
    }

    function _referral(
        address beneficiary,
        address referral,
        uint256 tokenAmount
    ) internal {
        require(_promo, 'no promotion');
        if (_referral_map[beneficiary] == address(0) && referral != address(0) && referral != beneficiary) {
            _referral_map[beneficiary] = referral;
        }

        if (_referral_map[beneficiary] != address(0)) {
            uint256 candy = tokenAmount.mul(_referral_rate).div(100);
            _token.sendCandy(_referral_map[beneficiary], candy);
            emit TokensReferral(_referral_map[beneficiary], candy);
        }
    }

    function _airdrop() internal {
        require(_promo, 'no promotion');
        require(_airdrop_map[msg.sender] == 0, 'cannot airdrop twice');
        uint256 candyAmount = 10 ether;
        _airdrop_map[msg.sender] = _airdrop_map[msg.sender].add(candyAmount);
        _token.sendCandy(msg.sender, candyAmount);
    }
}
