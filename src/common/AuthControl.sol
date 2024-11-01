//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {AuthRole} from "./AuthRole.sol";

contract AuthControl is AuthRole, ERC165, AccessControl {

    error ZeroAddress();
    error SameAdmin();
    error SameOwner();

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "AuthControl: Caller is not an admin");
        _;
    }

    modifier onlyOwner() {
        require(isOwner(), "AuthControl: Caller is not the owner");
        _;
    }

    modifier onlyPauser() {
        require(
            hasRole(PAUSE_ROLE, msg.sender),
            "AuthControl: Caller is not a pauser"
        );
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            isAdmin(msg.sender) || isOwner(),
            "not Owner or Admin"
        );
        _;
    }

    modifier onlyOwnerOrPauser() {
        require(
            hasRole(PAUSE_ROLE, msg.sender) || isOwner(),
            "AuthControl: Caller is not a pauser"
        );
        _;
    }

    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    function addPauser(address account) public virtual onlyOwner {
        grantRole(PAUSE_ROLE, account);
    }

    /// @dev remove admin
    function removeAdmin() public virtual onlyAdmin {
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    function removePauser(address account) public virtual onlyOwnerOrPauser {
        renounceRole(PAUSE_ROLE, account);
    }

    /// @dev transfer owner
    /// @param newOwner new owner address
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }
        
        if (msg.sender == newOwner) {
            revert SameOwner();
        }

        // granting owner and admin roles to the newOwner
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        grantRole(ADMIN_ROLE, newOwner);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function isOwner() public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isPauser(address account) public view virtual returns (bool) {
        return hasRole(PAUSE_ROLE, account);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
