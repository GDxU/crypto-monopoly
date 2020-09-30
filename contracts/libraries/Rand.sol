pragma solidity =0.6.6;

library Rand {
    function rand() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        (block.timestamp) +
                            (block.difficulty) +
                            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
                            (block.gaslimit) +
                            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
                            (block.number)
                    )
                )
            );
    }

    function rand16(uint256 min, uint256 max) internal view returns (uint16) {
        if (min == max) {
            return uint16(max);
        } else if (min > max) {
            uint256 m = min;
            min = max;
            max = m;
        }
        //uint256 r = rand();
        uint256 r = uint256(
            keccak256(abi.encodePacked(block.timestamp + uint256(keccak256(abi.encodePacked(msg.sender))) / now))
        );
        return uint16((r % (max - min)) + min);
    }
}
