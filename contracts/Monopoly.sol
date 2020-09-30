pragma solidity =0.6.6;

contract Monopoly {
    string public myString = 'Hello World';

    uint256[] private a;

    function set(string memory x) public {
        myString = x;
        a.push(1);
        a.push(2);
        a.push(3);
    }

    function reset() public {
        a.length = 0;
    }

    function len() public view returns (uint256) {
        return a.length;
    }

    function read(uint256 i) public view returns (uint256) {
        return a[i];
    }
}
