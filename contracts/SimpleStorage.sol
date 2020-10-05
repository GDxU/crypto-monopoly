pragma solidity ^0.6.0;

contract SimpleStorage {
    uint256 v;

    constructor() public {}

    // receive() external payable {}

    function set(uint256 _v) external {
        v = _v;
    }

    function get() public view returns (uint256) {
        return v;
    }
}
