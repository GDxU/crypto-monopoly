pragma solidity ^0.6.0;

import './libraries/TinyArray.sol';

contract TestTinyArray {
    using TinyArray for TinyArray.Data;
    TinyArray.Data tinyArray;

    constructor() public {
        tinyArray.init(5);
    }

    function init(uint16 v) public payable {
        tinyArray.init(v);
    }

    function push(uint16 v) public payable {
        tinyArray.push(v);
    }

    function index() public view returns (uint16) {
        return tinyArray.index;
    }

    function avg() public view returns (uint16) {
        return tinyArray.avg();
    }
}
