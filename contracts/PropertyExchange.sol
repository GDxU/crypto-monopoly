pragma solidity =0.6.6;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './libraries/SafeMath16.sol';
import './libraries/Rand.sol';
import './libraries/AdminRole.sol';
import './PropertyBase.sol';
import './PropertyOwnership.sol';
import './YopoToken.sol';

contract PropertyExchange is PropertyBase, AdminRole {
    using SafeMath16 for uint16;
    using SafeMath for uint256;
    PropertyOwnership private _po;
    YopoToken private _token;
    uint24 public round = 0;
    uint32 internal _offset = 0;
    uint256 public avgPrice = 0;

    uint8 private constant NUMBER_OF_PROPERTY = 40;
    mapping(uint32 => uint32[NUMBER_OF_PROPERTY]) private _propertyIndexes;

    event BurnHouse(address indexed from, uint32 indexed index, uint256 value);
    event Bankrupt(address indexed from);

    constructor(PropertyOwnership po, YopoToken token) public {
        _po = po;
        _token = token;
        // don't use first item
        properties.push(0);
        _reset(0, 10);
    }

    function newRound(uint24 _round, uint16 _avg) external onlyAdmin {
        _reset(_round, _avg);
    }

    function _reset(uint24 _round, uint16 _avg) internal {
        round = _round;
        _offset = uint32(properties.length);
        avgPrice = _avg;
    }

    /* mortgage houses to pay money to others */
    function mortgage(
        address player,
        address bank,
        uint256 token_load
    ) external onlyAdmin {
        //uint256 token_load = _price2Token(load_money);
        uint256 token_balance = _token.balanceOf(player);

        if (token_balance < token_load) {
            // levy houses
            uint256[] memory houseIds = _po.tokensOfOwner(player);
            if (houseIds.length > 0) {
                uint32[] memory pids = new uint32[](3);
                uint8 burn_num = 0;
                int256 i = int256(houseIds.length) - 1;
                while (i >= 0 && token_balance < token_load) {
                    uint32 index = uint32(houseIds[uint256(i)]);
                    if (!_isOnlinePropertyId(index)) {
                        break;
                    }

                    pids[burn_num] = index;
                    burn_num++;
                    uint16 buy_price = buyPriceById(index);
                    uint256 token_burn = _price2Token(buy_price);
                    token_balance = token_balance.add(token_burn);

                    if (burn_num >= 3) {
                        break;
                    }

                    i--;
                }

                uint8 j = 0;
                while (j < burn_num) {
                    // levy house
                    uint32 index = pids[j];
                    uint16 buy_price = buyPriceById(index);
                    uint256 token_refund = _price2Token(buy_price);
                    _levy(player, index);
                    emit BurnHouse(player, index, buy_price);
                    _token.safeTransfer(bank, player, token_refund);
                    j++;
                }
            }
        }

        uint256 bal = _token.balanceOf(msg.sender);
        if (bal <= token_load) {
            //token_load = bal;
            // bankrupt
            emit Bankrupt(msg.sender);
        }
    }

    function buy(
        address _buyer,
        uint16 _pos,
        uint16 _avgPrice
    ) external onlyAdmin {
        avgPrice = _avgPrice;
        if (_isRawLand(_pos)) {
            _buildProperty(_buyer, _pos);
        } else if (_canBuy(_buyer, _pos)) {
            _buyProperty(_buyer, _pos);
        }
    }

    function upgrade(uint16 _pos, bool _self) external onlyAdmin {
        _upgradeProperty(_pos, _self);
    }

    function getPropertyIndexes(uint24 _round) public view returns (uint32[NUMBER_OF_PROPERTY] memory) {
        return _propertyIndexes[_round];
    }

    function offset() public view returns (uint32, uint256) {
        return (_offset, properties.length);
    }

    function available(uint16 _pos) public view returns (bool) {
        return _isRawLand(_pos) || _hasProperty(_pos);
    }

    function hasProperty(uint16 _pos) public view returns (bool) {
        return _hasProperty(_pos);
    }

    function propertyId(uint16 _pos) public view returns (uint32) {
        return _getIndex(_pos);
    }

    function position(uint32 _index) public view returns (uint16) {
        return _getPos(_index);
    }

    function rentPrice(uint16 _pos) public view returns (uint16) {
        uint256 _p = _getOptionalProperty(_pos);
        if (_p == 0) {
            return 0;
        }

        return _getRentPrice(_p);
    }

    function buyPrice(uint16 _pos) public view returns (uint16) {
        uint256 _p = _getOptionalProperty(_pos);
        if (_p == 0) {
            return 0;
        }

        return _getBuyPrice(_p);
    }

    function buyPriceById(uint32 id) public view returns (uint16) {
        return _getBuyPrice(getPropertyById(id));
    }

    function rentPriceById(uint32 id) public view returns (uint16) {
        return _getRentPrice(getPropertyById(id));
    }

    function getPropertyById(uint32 index) public view returns (uint256) {
        if (_isOnlinePropertyId(index)) {
            return properties[index];
        }

        return 0;
    }

    function getProperty(uint16 _pos) public view returns (uint256) {
        return _getProperty(_pos);
    }

    function ownerOf(uint16 _pos) public view returns (address) {
        uint32 index = _getIndex(_pos);
        return _po.ownerOf(index);
    }

    function isOnlinePropertyId(uint32 index) public view returns (bool) {
        return _isOnlinePropertyId(index);
    }

    function isRawLand(uint16 _pos) public view returns (bool) {
        return _isRawLand(_pos);
    }

    function getProperties(address _owner) public view returns (uint16[] memory) {
        uint16 pos = 1;
        uint32[NUMBER_OF_PROPERTY] memory pis = getPropertyIndexes(round);
        uint16[] memory ps = new uint16[](NUMBER_OF_PROPERTY);
        uint16 _num = 0;

        while (pos < NUMBER_OF_PROPERTY) {
            if (pis[pos] != 0 && ownerOf(pos) == _owner) {
                ps[_num] = pos;
                _num++;
            }
            pos++;
        }

        uint16[] memory res = new uint16[](_num);
        uint16 j = 0;
        while (j < _num) {
            res[j] = ps[j];
            j++;
        }

        return res;
    }

    /*
        //TODO: use getPropertyIndexes to refactor
        function getProperties(address _owner) public view returns (uint16[] memory){
            uint256[] memory houseIds = _po.tokensOfOwner(_owner);
            if (houseIds.length > 0) {
                uint16 _num = 0;
                int i = int(houseIds.length) - 1;
                uint16[] memory ps = new uint16[](houseIds.length);
                while (i >= 0) {
                    uint32 index = uint32(houseIds[uint(i)]);
                    if (!_isOnlinePropertyId(index)) {
                        break;
                    }
                    uint16 _pos = _getPos(index);
                    ps[_num] = _pos;
                    _num++;
                    i--;
                }

                uint16[] memory res = new uint16[](_num);
                uint16 j = 0;
                while (j < _num) {
                    res[j] = ps[j];
                    j++;
                }

                return res;
            }
        }*/

    function getPropertySummary(address _owner) public view returns (uint16, uint256) {
        uint16 pos = 1;
        uint32[NUMBER_OF_PROPERTY] memory pis = getPropertyIndexes(round);
        uint16 _num = 0;
        uint256 _fund = 0;

        while (pos < NUMBER_OF_PROPERTY) {
            if (pis[pos] != 0 && ownerOf(pos) == _owner) {
                _num++;
                _fund = _fund.add(buyPrice(pos));
            }
            pos++;
        }

        return (_num, _fund);
    }

    function getNewestPrice(uint16 _pos) public view returns (uint16, uint16) {
        return _getNewestPrice(_pos);
    }

    function price2Token(uint256 _price) public pure returns (uint256) {
        return _price2Token(_price);
    }

    /**************************** internal functions ********************************/

    function _price2Token(uint256 _price) private pure returns (uint256) {
        return uint256(_price).mul(1 ether);
    }

    function _levy(address from, uint32 index) internal {
        _po.transfer(from, address(0), index);
        properties[index] = 0;
        //TODO change get pos method
        _propertyIndexes[round][_getPos(index)] = 0;
        _setIndex(0, index);
    }

    function _buildProperty(address _buyer, uint16 _pos) internal {
        (uint16 _buy_price, uint16 _rent_price) = _getNewestPrice(_pos);
        _buildProperty(_buyer, _pos, _buy_price, _rent_price);
    }

    function _buildProperty(
        address _buyer,
        uint16 _pos,
        uint16 _buy_price,
        uint16 _rent_price
    ) internal {
        /* 32b: gene, 32[40b]: time, 72[16b]: buy price, 88[16b]: rent price, 104:  */
        uint256 _gene_n_date = uint32(Rand.rand()) | (uint256(uint40(now)) << 32);
        uint256 _property = _gene_n_date | (uint256(_buy_price) << 72) | (uint256(_rent_price) << 88);
        uint32 _index = uint32(properties.length);
        _setIndex(_pos, _index);
        properties.push(_property);
        _po.transfer(address(0), _buyer, _index);
        _propertyIndexes[round][_pos] = _index;
    }

    function _buyProperty(address _buyer, uint16 _pos) internal {
        (uint16 _buy_price, uint16 _rent_price) = _getNewestPrice(_pos);
        /* 32b: gene, 32[40b]: time, 72[16b]: buy price, 88[16b]: rent price, 104:  */
        uint32 _index = _getIndex(_pos);
        uint256 _property = properties[_index];
        //uint16 _rent_price = _getRentPrice(_property).add(_buy_price >> 3);
        uint256 _gene_n_date = _property & (0xFFFFFFFFFFFFFFFFFF);
        /*2**72-1*/
        uint256 new_property = _gene_n_date | (uint256(_buy_price) << 72) | (uint256(_rent_price) << 88);
        properties[_index] = new_property;
        address _owner = _po.ownerOf(_index);
        _po.transfer(_owner, _buyer, _index);
        _propertyIndexes[round][_pos] = _index;
    }

    function _upgradeProperty(uint16 _pos, bool _self) internal {
        /* 32b: gene, 32[40b]: time, 72[16b]: buy price, 88[16b]: rent price, 104:  */
        uint32 _index = _getIndex(_pos);
        uint256 _property = properties[_index];
        uint16 _buy_price = _getBuyPrice(_property);
        uint16 _rent_price = _getRentPrice(_property);
        if (_self) {
            _buy_price += _buy_price / 10;
            _rent_price += _rent_price / 10;
        } else {
            _rent_price += _rent_price / 2;
        }

        _buy_price = _limit(_buy_price, 10000);
        _rent_price = _limit(_rent_price, 5000);

        /*2**72-1*/
        uint256 _gene_n_date = _property & (0xFFFFFFFFFFFFFFFFFF);
        uint256 new_property = _gene_n_date | (uint256(_buy_price) << 72) | (uint256(_rent_price) << 88);
        properties[_index] = new_property;
        //_calAvgPrice(_buy_price);
        //trades++;
    }

    function _canBuy(address _buyer, uint16 _pos) internal view returns (bool) {
        uint32 index = _getIndex(_pos);
        if (_isOnlinePropertyId(index)) {
            uint256 _p = properties[index];
            // cannot buy own house
            if (_p != 0 && _po.ownerOf(index) != _buyer) {
                return true;
            }
        }

        return false;
    }

    //    function _calAvgPrice(uint16 _buy_price) private {
    //        avgPrice = avgPrice.mul(trades).add(_buy_price).div(trades + 1);
    //    }

    function _getNewestPrice(uint16 _pos) internal view returns (uint16, uint16) {
        uint256 p = _getOptionalProperty(_pos);
        if (p == 0) {
            //raw land
            //cpi.mul(uint16(r & 0x7).add(5)).add(uint16(avgPrice) >> 1);
            //cpi.mul(uint16(r & 0x3).add(2)).add(uint16(avgPrice) >> 2);
            uint16 buy_price = Rand.rand16(avgPrice >> 1, (avgPrice * 3) / 2);
            uint16 rent_price = Rand.rand16(avgPrice >> 2, avgPrice);
            buy_price = _limit(buy_price, 10000);
            rent_price = _limit(rent_price, 5000);
            return (buy_price, rent_price);
        } else {
            uint16 buy_price = _getBuyPrice(p);
            uint16 rent_price = _getRentPrice(p);
            //        uint16 new_price = uint16(((buy_price * 3) / 2) + (rent_price >> 1) + (avgPrice >> 1) );//+ rent_price >> 1 + avgPrice) >> 1
            //        if (new_price > 10000) {
            //            new_price = 10000;
            //        }
            /* price += (rand(avg/4, avg/2) );
            rent +=  rand(price/8, price/2); */
            buy_price += Rand.rand16(avgPrice >> 2, avgPrice >> 1);
            buy_price = _limit(buy_price, 10000);
            rent_price += Rand.rand16(buy_price >> 3, buy_price >> 1);
            rent_price = _limit(rent_price, 5000);
            return (buy_price, rent_price);
        }
    }

    function _limit(uint16 v, uint16 max) private pure returns (uint16) {
        return v < max ? v : max;
    }

    function _getBuyPrice(uint256 value) internal pure returns (uint16) {
        /*2**16-1*/
        return uint16((value >> 72) & (0xFFFF));
    }

    function _getRentPrice(uint256 value) internal pure returns (uint16) {
        return uint16((value >> 88) & (0xFFFF));
    }

    function _getProperty(uint16 _pos) internal view returns (uint256) {
        uint32 index = _getIndex(_pos);
        require(_isOnlinePropertyId(index), 'out of index range');
        return properties[index];
    }

    function _isRawLand(uint16 _pos) internal view returns (bool) {
        uint32 index = _getIndex(_pos);
        if (index == 0) {
            return true;
        }

        /* consider levying houses */
        if (_isOnlinePropertyId(index)) {
            return properties[index] == 0;
        }

        return false;
    }

    function _hasProperty(uint16 _pos) internal view returns (bool) {
        return _getOptionalProperty(_pos) != 0;
    }

    function _getOptionalProperty(uint16 _pos) internal view returns (uint256) {
        uint32 index = _getIndex(_pos);
        if (_isOnlinePropertyId(index)) {
            return properties[index];
        }
        return 0;
    }

    function _setIndex(uint16 _pos, uint32 _index) internal {
        //posToIndex[uint32(_pos) + _offset] = _index;
        indexToPos[_index] = _pos;
    }

    function _getIndex(uint16 _pos) internal view returns (uint32) {
        return _propertyIndexes[round][_pos];
        //posToIndex[uint32(_pos) + _offset];
    }

    function _getPos(uint32 _index) internal view returns (uint16) {
        return indexToPos[_index];
    }

    function _isOnlinePropertyId(uint32 index) internal view returns (bool) {
        return (index >= _offset && index < properties.length);
    }
}
