pragma solidity =0.6.6;

import './libraries/Rand.sol';

contract TestRand {
    uint256 public v = 0;

    constructor() public {}

    function rand() public view returns (uint8, uint8) {
        uint256 n = Rand.rand();
        //2**128-1
        uint256 n1 = n & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 n2 = n >> 128;
        return (uint8((n1 % 6) + 1), uint8((n2 % 6) + 1));
    }

    function set(uint16 _v) public payable {
        v = _v;
    }
}
