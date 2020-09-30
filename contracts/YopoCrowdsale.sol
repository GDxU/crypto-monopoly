pragma solidity =0.6.6;

import 'openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol';
import 'openzeppelin-solidity/contracts/crowdsale/validation/PausableCrowdsale.sol';
import 'openzeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol';
import 'openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './YopoToken.sol';
import './YopoReferral.sol';
import './libraries/AdminRole.sol';

contract YopoCrowdsale is AdminRole, PausableCrowdsale, MintedCrowdsale, YopoReferral {
    uint256 private _commission;
    uint256 private _sell_rate;
    YopoToken private _token;

    /**
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * 1 ETH = 1000 YOP
     * @param rate Number of token units a buyer gets per wei
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     */
    constructor(
        uint256 rate,
        address payable wallet,
        YopoToken token,
        uint256 cap
    )
        public
        Crowdsale(rate, wallet, token)
        //CappedCrowdsale(cap)CappedCrowdsale,
        YopoReferral(token)
    {
        //As goal needs to be met for a successful crowdsale
        //the value needs to less or equal than a cap which is limit for accepted funds
        //require(goal <= cap);
        _token = token;
        // 10% commission, +rate/9; 1%, +rate/99;
        _sell_rate = rate.add(rate / 9);
    }

    /**
     * @return the amount of commission.
     */
    function commission() public view returns (uint256) {
        return _commission;
    }

    /**
     * @return sell rate.
     */
    function sell_rate() public view returns (uint256) {
        return _sell_rate;
    }

    /**
     * set the amount of sell rate.
     */
    function set_sell_rate(uint256 rate) public payable onlyAdmin {
        if (rate > 0) {
            _sell_rate = rate;
        }
    }

    /**
     * @dev buy tokens
     * @param beneficiary Recipient of the token purchase
     */
    function buy(address beneficiary, address referral) public payable {
        /* This function has a non-reentrancy guard, so it shouldn't be called by another `nonReentrant` function. */
        buyTokens(beneficiary);

        if (promotion()) {
            uint256 tokenAmount = _getTokenAmount(msg.value);
            uint256 candyAmount = 0;

            if (msg.value < 1 ether) {
                // do nothing
            } else if (msg.value < 5 ether) {
                candyAmount = tokenAmount.mul(5).div(100);
            } else if (msg.value < 10 ether) {
                candyAmount = tokenAmount.mul(10).div(100);
            } else {
                candyAmount = tokenAmount.mul(15).div(100);
            }
            if (candyAmount > 0) {
                _token.sendCandy(beneficiary, candyAmount);
            }

            _referral(beneficiary, referral, tokenAmount);
        }
    }

    function() external payable {
        if (msg.value > 0) {
            //buyTokens(msg.sender);
        } else {
            _airdrop();
        }
    }

    function airdrop() public payable {
        _airdrop();
    }

    /**
     * @dev pay tax
     * @param _account account .
     * @param _tax tax coins.
     */
    function payTax(address _account, uint256 _tax) external onlyAdmin {
        //        uint256 candyAmount = _token.candyOf(_account);
        //        if (candyAmount < _tax) {
        //            _tax = _tax.sub(candyAmount);
        //            _commission = _commission.add(_tax);
        //        }
        _commission = _commission.add(toWei(_tax));
        _token.safeBurn(_account, _tax);
    }

    /**
     * @dev award ETH
     * @param _account account .
     * @param _value award coins.
     */
    function award(address _account, uint256 _value) external onlyAdmin {
        require(_value > _sell_rate, 'value is too small');
        uint256 wei_val = toWei(_value);
        require(wei_val > 0, 'less than 1 wei');
        require(address(this).balance >= wei_val, 'balance > transferred value');
        msg.sender.transfer(wei_val);
    }

    //TODO: unsafe, remove it
    /**
     * @dev claim ETH
     * @param _value refund coins.
     */
    function refund(uint256 _value) public payable {
        uint256 bal = _token.tokenOf(msg.sender);
        require(bal >= _value, 'insufficient token');
        require(_value > _sell_rate, 'value is too small');
        uint256 wei_val = toWei(_value);
        require(wei_val >= 0.001 ether, 'less than 0.001 ether');
        require(address(this).balance >= wei_val, 'balance > transferred value');
        require(_token.safeRefund(msg.sender, _value), 'refund fails');
        msg.sender.transfer(wei_val);
    }

    function toWei(uint256 _value) public view returns (uint256) {
        return _value.div(refundRate());
    }

    function refundRate() public view returns (uint256) {
        uint256 token_rate = _token.tokenRate();
        if (token_rate == 0) {
            token_rate = 1;
        }
        return (_sell_rate).mul(1000).div(token_rate).add(1);
    }

    /**
     * @dev Release commission
     */
    function releaseCommission() public payable onlyAdmin {
        _releaseCommission();
    }

    function _releaseCommission() internal {
        require(_commission > 0, 'commission should be > 0');
        wallet().transfer(_commission);
        _commission = 0;
    }

    /**
     * @dev overwrite
     */
    function _forwardFunds() internal {
        // do not forward funds until
        _commission = _commission.add(msg.value / 10);
        _releaseCommission();
    }

    /**
     * @dev overwrite
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeMint(beneficiary, tokenAmount);
    }
}
