pragma solidity ^0.6.0;

library SafeMath16 {
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        require(c / a == b, 'overflow in mul');
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        require(b > 0, 'overflow in div'); // Solidity automatically throws when dividing by 0
        uint16 c = a / b;
        // require(a == b * c + a % b); // There is no case in which this doesn’t hold
        return c;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        require(b <= a, 'overflow in sub');
        return a - b;
    }

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        require(c >= a, 'overflow in add');
        return c;
    }
}
