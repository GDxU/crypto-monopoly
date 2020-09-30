pragma solidity =0.6.6;

contract TestBF {
    function avg_tran(address[] memory dists) public payable {
        uint256 v = msg.value / dists.length;
        for (uint256 i = 0; i < dists.length; i++) {
            address payable dist = address(uint160(dists[i]));
            dist.transfer(v);
        }
    }
}
