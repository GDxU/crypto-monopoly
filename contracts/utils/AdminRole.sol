pragma solidity ^0.6.0;

import '@openzeppelin/contracts/access/AccessControl.sol';

contract AdminRole is AccessControl {
    // the super admin can assign someone to be a genneral admin role
    bytes32 public constant SUPER_ROLE = keccak256('SUPER');
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN');

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    address payable public me = 0x6666666666666666666666666666666666666666;

    constructor() internal {
        me = msg.sender;
        _setupRole(SUPER_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, SUPER_ROLE);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), 'sender is not an admin');
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        grantRole(ADMIN_ROLE, account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        renounceRole(ADMIN_ROLE, account);
        emit AdminRemoved(account);
    }

    function close() public payable {
        require(msg.sender == me, 'sender is not owner');
        selfdestruct(me);
    }
}
