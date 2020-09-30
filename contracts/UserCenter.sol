pragma solidity =0.6.6;

import './libraries/AdminRole.sol';

contract UserCenter is AdminRole {
    address[] private _users;

    /* 0-160: address, 176: pos, 192: total steps */
    mapping(address => uint256) private _addressToUser;

    /**
     * Event for user register logging
     */
    event UserRegistered(address indexed user, uint256 value);

    function register(address _addr) external onlyAdmin {
        _register(_addr);
    }

    function _register(address _addr) internal {
        require(_addr != address(0), 'invalid address');
        require(!_exists(_addr), 'user exists');
        uint256 c = uint256(_addr);
        c |= (_users.length << 160);
        _addressToUser[_addr] = c;
        _users.push(_addr);

        emit UserRegistered(_addr, c);
    }

    function exists(address _addr) public view returns (bool) {
        return _exists(_addr);
    }

    function _exists(address _addr) internal view returns (bool) {
        require(_addr != address(0), 'invalid address');
        return _addressToUser[_addr] != 0;
    }

    function totalUsers() public view returns (uint256) {
        return _users.length;
    }

    function getUserInfo(address _addr, uint24 _round)
        public
        view
        returns (
            uint24,
            uint16,
            uint16,
            uint16,
            uint24
        )
    {
        if (!_exists(_addr)) {
            return (0, 0, 0, 0, 0);
        }
        uint256 c = _addressToUser[_addr];
        require(_addr == address(c), 'address not match in getUserInfo');
        uint24 index = uint24(c >> 160);
        uint24 round = uint24(c >> 232);
        if (round == _round) {
            uint16 pos = uint16(c >> 184);
            uint16 total_steps = uint16(c >> 200);
            uint16 roll = uint16(c >> 216);
            return (index, pos, total_steps, roll, round);
        } else {
            return (index, 0, 0, 0, _round);
        }
    }

    function setUserInfo(
        address _addr,
        uint16 _pos,
        uint16 _total_steps,
        uint16 _roll,
        uint24 _round
    ) external onlyAdmin {
        if (!_exists(_addr)) {
            _register(_addr);
        }
        uint256 c = _addressToUser[_addr];
        require(_addr == address(c), 'address not match in setUserInfo');

        // bits [addr + index] = 2**184-1
        uint256 mask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        c &= mask;
        c |= (uint256(_pos) << 184);
        c |= (uint256(_total_steps) << 200);
        c |= (uint256(_roll) << 216);
        c |= (uint256(_round) << 232);
        _addressToUser[_addr] = c;
    }

    function getRoll(address _addr, uint24 _round) public view returns (uint8, uint8) {
        uint256 c = _addressToUser[_addr];
        uint24 round = uint24(c >> 232);
        if (round == _round) {
            uint16 roll = uint16(c >> 216);
            return (uint8(roll >> 3), uint8(roll & 0x7));
        } else {
            return (0, 0);
        }
    }

    function getPos(address _addr, uint24 _round) public view returns (uint16) {
        uint256 c = _addressToUser[_addr];
        uint24 round = uint24(c >> 232);
        if (round == _round) {
            uint16 pos = uint16(c >> 184);
            return pos;
        } else {
            return 0;
        }
    }

    function getPosAndSteps(address _addr, uint24 _round) public view returns (uint16, uint16) {
        uint256 c = _addressToUser[_addr];
        uint24 round = uint24(c >> 232);
        if (round == _round) {
            uint16 pos = uint16(c >> 184);
            uint16 total_steps = uint16(c >> 200);
            return (pos, total_steps);
        } else {
            return (0, 0);
        }
    }
}
