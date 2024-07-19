//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AuthRoleGemFactory.sol";

contract AuthControlGemFactory is AuthRoleGemFactory, ERC165, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender), "AuthControl: Caller is not an admin");
        _;
    }

    modifier onlyTreasury() {
        require(
            hasRole(TREASURY_ROLE, msg.sender),
            "AuthControl: Caller is not a minter"
        );
        _;
    }

    modifier onlyPauser() {
        require(
            hasRole(PAUSE_ROLE, msg.sender),
            "AuthControl: Caller is not a pauser"
        );
        _;
    }

    modifier onlyTreasuryOrAdmin() {
        require(
            isAdmin(msg.sender) || hasRole(TREASURY_ROLE, msg.sender),
            "not onlyMinterOrAdmin"
        );
        _;
    }

    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyOwner {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function addMinter(address account) public virtual onlyOwner {
        grantRole(TREASURY_ROLE, account);
    }

    /// @dev remove admin
    /// @param account  address to remove
    function removeAdmin(address account) public virtual onlyOwner {
        renounceRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeMinter(address account) public virtual onlyOwner {
        renounceRole(TREASURY_ROLE, account);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) public virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function transferOwnership(address newAdmin) public virtual onlyOwner {
        transferAdmin(newAdmin);
    }

    function renounceOwnership() public onlyOwner {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function renounceMinter() public {
        renounceRole(TREASURY_ROLE, msg.sender);
    }

    function revokeMinter(address account) public onlyOwner {
        revokeRole(TREASURY_ROLE, account);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isOwner() public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isMinter(address account) public view virtual returns (bool) {
        return hasRole(TREASURY_ROLE, account);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
