pragma solidity =0.6.6;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import './libraries/SafeMath16.sol';
import './libraries/Rand.sol';
import './libraries/AdminRole.sol';
import './libraries/TinyArray.sol';
import './PropertyOwnership.sol';
import './PropertyExchange.sol';
import './YopoToken.sol';
import './YopoCrowdsale.sol';
import './UserCenter.sol';
import './Gov.sol';

contract Game is AdminRole, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath16 for uint16;
    using TinyArray for TinyArray.Data;

    TinyArray.Data private _avgPrices;
    PropertyOwnership private _po;
    PropertyExchange private _pe;
    YopoToken private _token;
    YopoCrowdsale private _exchange;
    UserCenter private _uc;
    Gov private _gov;

    uint8 private constant NUMBER_OF_PROPERTY = 40;
    uint256 public endTime = 0;

    uint16 public constant version = 10001; //v1.0.1
    uint24 public round = 0;
    uint16 public steps = 0;
    //uint256 public penaltyPool = 0;
    uint32 public numberOfMove = 0;
    uint32 public maxNumberOfMove = 200;
    uint16 public numberOfProperty = 0;
    uint16 public initAvgPrice = 10;

    event NewGame(address indexed from, uint24 round);
    event Move(address indexed from, uint16 lastPos, uint16 pos, uint8 r1, uint8 r2);
    event PayRent(address indexed from, uint16 indexed pos, uint256 value);
    event BuyHouse(address indexed from, uint16 indexed pos, uint32 index, uint256 value);
    event UpgradeHouse(address indexed from, uint16 indexed pos, uint256 value);
    event Reward(uint8 indexed group, address indexed from, uint16 indexed pos, uint256 value);
    event Win(address indexed from, uint24 indexed round, uint256 value, uint16 numberOfProperty, uint256 time);

    modifier onlyMember() {
        require(msg.sender != address(0), 'sender address is 0x0');
        require(_token.balanceOf(msg.sender) > 0, 'member has no token');
        //require(_uc.exists(msg.sender), "user not exists");
        _;
    }

    function setup(
        PropertyOwnership po,
        PropertyExchange pe,
        YopoToken token,
        YopoCrowdsale exchange,
        UserCenter uc,
        Gov gov
    ) public onlyAdmin {
        _po = po;
        _pe = pe;
        _token = token;
        _exchange = exchange;
        _uc = uc;
        _gov = gov;
        _newGame();
    }

    function _newGame() private {
        round += 1;
        steps = 0;
        //penaltyPool = 0;
        numberOfMove = 0;
        numberOfProperty = 0;
        endTime = now.add(1 days);
        _pe.newRound(round, initAvgPrice);
        _avgPrices.init(5);
        _avgPrices.push(initAvgPrice);
        _gov.newRound(round);

        emit NewGame(msg.sender, round);
    }

    function() external payable onlyMember {
        move();
    }

    function move() public payable onlyMember {
        (uint8 r1, uint8 r2) = _roll2();
        _move(r1, r2, false);
    }

    // *********** for test only ****************/
    //    function moveTo(uint8 r1, uint8 r2) public payable onlyMember {
    //        _move(r1, r2, true);
    //    }

    function _move(
        uint8 r1,
        uint8 r2,
        bool fixedMove
    ) private {
        uint16 pos = 0;
        uint16 total_steps = 0;

        if (_isGameOver()) {
            _award();
            _newGame();
        } else {
            (pos, total_steps) = _uc.getPosAndSteps(msg.sender, round);
        }

        uint16 roll_sum = _rollSum(r1, r2);
        uint16 roll_value = _rollValue(r1, r2);

        //        if (pos == 0 && total_steps == 0 && !fixedMove) {
        //            // random move
        //            pos = (roll_value % 4) * (NUMBER_OF_PROPERTY >> 2);
        //        }

        uint16 lastPos = pos;
        pos = pos + roll_sum;

        if (pos >= NUMBER_OF_PROPERTY) {
            // last position
            pos = pos - NUMBER_OF_PROPERTY;
        }
        total_steps = total_steps.add(roll_sum);
        steps = steps.add(roll_sum);
        _uc.setUserInfo(msg.sender, pos, total_steps, roll_value, round);
        numberOfMove += 1;
        if (endTime < now.add(23 hours)) {
            // add 5 minute
            endTime = endTime.add(5 minutes);
        }
        emit Move(msg.sender, lastPos, pos, r1, r2);

        // check gov
        if (pos == 0) {
            // first pos, nothing to do.
        } else if (_isJail(pos)) {
            uint256 token_penalty = _price2Token(_jailPenalty());
            _gov.fine(1, msg.sender, address(this), pos, token_penalty);
            //penaltyPool = penaltyPool.add(token_penalty);
            return;
        } else if (_isLottery(pos)) {
            uint256 _bonus = _lotteryReward();
            _token.safeTransfer(address(this), msg.sender, _bonus);
            emit Reward(1, msg.sender, pos, _bonus);
        } else if (_isQuestionMark(pos)) {
            uint16 fee_question = _questionMarkFee();
            uint256 token_question = _price2Token(fee_question);
            uint256 n = Rand.rand();
            if ((n % 10) < 4) {
                // 40% reward
                _token.safeTransfer(address(this), msg.sender, token_question);
                emit Reward(2, msg.sender, pos, token_question);
            } else {
                _gov.fine(2, msg.sender, address(this), pos, token_question);
                //penaltyPool = penaltyPool.add(token_question);
            }
        } else {
            // check rent
            if (_pe.hasProperty(pos)) {
                uint32 _index = _pe.propertyId(pos);
                address _owner = _po.ownerOf(_index);
                if (_owner == msg.sender) {
                    // my house, rent go up!
                    _pe.upgrade(pos, true);
                } else {
                    // someone's house, pay rent
                    uint16 rent_fee = _pe.rentPrice(pos);
                    _pe.upgrade(pos, false);

                    uint256 token_rent = _price2Token(rent_fee);
                    _pe.mortgage(msg.sender, address(this), token_rent);

                    if (!_inJail(_owner)) {
                        // rent
                        // 12.5% to bonus pool
                        uint256 _bonus = token_rent >> 3;
                        _token.safeTransfer(msg.sender, _owner, token_rent.sub(_bonus));
                        _token.safeTransfer(msg.sender, address(this), _bonus);
                    } else {
                        // owner is in jail, pay to prize pool
                        _token.safeTransfer(msg.sender, address(this), token_rent);
                    }
                    emit PayRent(msg.sender, pos, rent_fee);
                }
            }
        }
    }

    function buy() public payable onlyMember nonReentrant {
        //TODO: move the buy logic to PropertyExchange contract
        uint16 _pos = _uc.getPos(msg.sender, round);
        require(_checkPos(_pos), 'no land or house to buy');

        uint32 _index = _pe.propertyId(_pos);
        address _owner = _po.ownerOf(_index);
        require(_owner != msg.sender, 'cannot buy own house');

        _pe.buy(msg.sender, _pos, avgPrice());
        uint16 new_price = _pe.buyPrice(_pos);
        _avgPrices.push(new_price);

        uint256 token_amount = _token.balanceOf(msg.sender);
        uint256 token_buy = _price2Token(new_price);
        require(token_amount >= token_buy, 'insufficient token');

        if (_owner == address(0) || _owner == address(this)) {
            // new house
            _exchange.payTax(msg.sender, token_buy / 10);
            _token.safeTransfer(msg.sender, address(this), token_buy.sub(token_buy / 10));
            //_propertyPositions[round].push(_pos);
            //_propertyIndexes[round][_pos] = _pe.propertyId(_pos);//1;//_index;
            numberOfProperty++;
        } else {
            // pay to game
            uint256 _tax = token_buy / 15;
            uint256 _gameProfit = token_buy / 10;
            _exchange.payTax(msg.sender, _tax);
            _token.safeTransfer(msg.sender, address(this), _gameProfit);
            _token.safeTransfer(msg.sender, _owner, token_buy.sub(_tax).sub(_gameProfit));
        }

        _index = _pe.propertyId(_pos);
        emit BuyHouse(msg.sender, _pos, _index, new_price);
    }

    function setMaxNumberOfMove(uint32 maxValue) public payable onlyAdmin {
        maxNumberOfMove = maxValue;
    }

    function setAvgPrice(uint16 _p) public payable onlyAdmin {
        initAvgPrice = _p;
    }

    function getPos(address account) public view returns (uint16) {
        return _uc.getPos(account, round);
    }

    function getWinner()
        public
        view
        returns (
            address,
            uint16,
            uint256,
            uint256
        )
    {
        (address _winner, uint16 _num, uint256 _fund, uint256 _total) = _getWinner();
        return (_winner, _num, _fund, _total);
    }

    function canBuy(uint16 pos) public view returns (bool) {
        return _checkPos(pos);
    }

    function avgPrice() public view returns (uint16) {
        return _avgPrices.avg();
    }

    function jailPenalty() public view returns (uint16) {
        return _jailPenalty();
    }

    function bonusPool() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function lotteryReward() public view returns (uint256) {
        return _lotteryReward();
    }

    /*************************** private *****************************************/
    function _rollValue(uint8 r1, uint8 r2) private pure returns (uint16) {
        return uint16((r1 << 3) | r2);
    }

    function _rollSum(uint8 r1, uint8 r2) private pure returns (uint16) {
        return uint16(r1 + r2);
    }

    function _roll2() private view returns (uint8, uint8) {
        uint256 n = Rand.rand();
        //2**128-1
        uint256 n1 = n & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 n2 = n >> 128;
        return (uint8((n1 % 6) + 1), uint8((n2 % 6) + 1));
    }

    function _price2Token(uint256 _price) private pure returns (uint256) {
        return uint256(_price).mul(1 ether);
    }

    function _token2Price(uint256 token) private pure returns (uint256) {
        return uint16(token.div(1 ether));
    }

    function _inJail(address from) private view returns (bool) {
        return _isJail(_uc.getPos(from, round));
    }

    function _checkPos(uint16 pos) private view returns (bool) {
        return
            pos < NUMBER_OF_PROPERTY &&
            !_isFreeParking(pos) &&
            !_isJail(pos) &&
            !_isLottery(pos) &&
            !_isQuestionMark(pos) &&
            _pe.available(pos) &&
            _pe.ownerOf(pos) != msg.sender;
    }

    function _isJail(uint16 pos) private view returns (bool) {
        return _gov.meet(pos);
        //return pos == 10 || pos == 30;
    }

    function _isLottery(uint16 pos) private pure returns (bool) {
        return pos == 17;
    }

    function _isQuestionMark(uint16 pos) private pure returns (bool) {
        return pos == 7 || pos == 22 || pos == 36;
    }

    function _isFreeParking(uint16 pos) private pure returns (bool) {
        return pos == 0 || pos == 20;
    }

    /* Gov */
    function _jailPenalty() private view returns (uint16) {
        return uint16(100 + 10 * (numberOfMove / 10));
    }

    function _questionMarkFee() private view returns (uint16) {
        return uint16(20 + 10 * (numberOfMove / 10));
    }

    function _lotteryReward() private view returns (uint256) {
        return _token.balanceOf(address(this)) >> 2;
    }

    function _isGameOver() private view returns (bool) {
        return numberOfMove >= maxNumberOfMove - 1 || now >= endTime;
    }

    function _award() private {
        (address _winner, uint16 _num, uint256 _fund, uint256 _total) = _getWinner();
        // no one wins
        if (_winner == address(0)) {
            emit Win(_winner, round, _total, _num, now);
            return;
        }

        _total = bonusPool();

        //10% for the commission
        _exchange.payTax(address(this), _total / 10);

        //60%
        uint256 bonus = _total.mul(60).div(100);
        _token.safeTransfer(address(this), _winner, bonus);

        //30% left for the next game's bonus

        emit Win(_winner, round, bonus, _num, now);
    }

    function _getWinner()
        private
        view
        returns (
            address,
            uint16,
            uint256,
            uint256
        )
    {
        uint16 pos = 1;
        uint256 _total_fund = 0;
        address _winner = address(0);
        uint16 _max_num = 0;
        uint256 _max_fund = 0;
        bool[] memory hits = new bool[](NUMBER_OF_PROPERTY + 1);
        while (pos < NUMBER_OF_PROPERTY) {
            if (!hits[pos] && _pe.hasProperty(pos)) {
                address _owner = _pe.ownerOf(pos);
                if (_owner != address(0)) {
                    uint256[] memory houseIds = _po.tokensOfOwner(_owner);
                    if (houseIds.length > 0) {
                        uint256 _fund = 0;
                        uint16 _num = 0;
                        int256 i = int256(houseIds.length) - 1;
                        while (i >= 0) {
                            uint32 index = uint32(houseIds[uint256(i)]);
                            if (!_pe.isOnlinePropertyId(index)) {
                                break;
                            }
                            uint16 _pos = _pe.position(index);
                            hits[_pos] = true;
                            _fund = _fund.add(_pe.buyPrice(_pos));
                            //_fund.add(_pe.buyPriceById(index));
                            _num++;
                            i--;
                        }

                        _total_fund = _total_fund.add(_fund);
                        if (_num > _max_num) {
                            _max_num = _num;
                            _winner = _owner;
                            _max_fund = _fund;
                        } else if (_num == _max_num && _fund > _max_fund) {
                            _winner = _owner;
                            _max_fund = _fund;
                        }
                    }
                }
            }
            pos++;
        }

        return (_winner, _max_num, _max_fund, _price2Token(_total_fund));
    }
}
