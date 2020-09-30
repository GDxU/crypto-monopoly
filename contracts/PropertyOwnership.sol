pragma solidity =0.6.6;

import 'openzeppelin-solidity/contracts/token/ERC721/ERC721.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol';
import './libraries/AdminRole.sol';
import './PropertyEnumerable.sol';

contract PropertyOwnership is AdminRole, ERC721, ERC721Metadata, PropertyEnumerable {
    constructor() public ERC721Metadata('MONOPOLY', 'MON') {}

    function transfer(
        address _from,
        address _to,
        uint256 _id
    ) external onlyAdmin {
        if (_from == address(0)) {
            _mint(_to, _id);
        } else if (_to == address(0)) {
            _burn(_from, _id);
        } else {
            _transferFrom(_from, _to, _id);
        }
    }

    /* override ERC721*/
    function ownerOf(uint256 id) public view returns (address) {
        if (_exists(id)) {
            return super.ownerOf(id);
        }

        return address(0);
    }
}
