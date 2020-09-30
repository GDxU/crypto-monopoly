pragma solidity =0.6.6;

import './SafeMath16.sol';

library TinyArray {
    using SafeMath16 for uint16;
    struct Data {
        uint16[] array;
        uint16 index;
        uint16 maxLength;
    }

    function init(Data storage self, uint16 maxLength) internal {
        //self =  Data({array: new uint16[](0), index:0, maxLength: 5});
        self.maxLength = maxLength;
        clear(self);
    }

    function push(Data storage self, uint16 value) internal {
        if (self.array.length >= self.maxLength) {
            self.array[self.index] = value;
        } else {
            self.array.push(value);
        }
        self.index++;
        if (self.index >= self.maxLength) {
            self.index = 0;
        }
    }

    function avg(Data memory self) internal pure returns (uint16) {
        if (self.array.length == 0) {
            return 0;
        }
        uint16 i = 0;
        uint256 total = 0;
        while (i < self.array.length) {
            total += self.array[i];
            i++;
        }
        return uint16(total / self.array.length);
    }

    function clear(Data storage self) internal {
        delete self.array; //.length = 0;
        self.index = 0;
    }
}
