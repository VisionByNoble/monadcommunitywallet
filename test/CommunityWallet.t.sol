// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// This contract allows a group of members to manage a community wallet. Members can send funds to other addresses, and the owner can add or remove members and transfer ownership.

contract CommunityWallet is ReentrancyGuard {
    address public owner;
    mapping(address => bool) public members;

    // Events
    event FundsSent(address indexed to, uint256 amount);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action!");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "You're not a member!");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        members[msg.sender] = true; // Owner is a member by default
    }

    // Add a member (only owner can do this)
    function addMember(address _member) public onlyOwner {
        require(!members[_member], "Member already added!");
        members[_member] = true;
        emit MemberAdded(_member);
    }

    // Remove a member (only owner can do this)
    function removeMember(address _member) public onlyOwner {
        require(members[_member], "Address is not a member!");
        members[_member] = false;
        emit MemberRemoved(_member);
    }

    // Transfer ownership (only owner can do this)
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address!");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Send funds to another address (only members can do this)
    function sendMoney(address payable _to, uint256 _amount) public onlyMembers nonReentrant {
        require(address(this).balance >= _amount, "Insufficient balance in wallet");
        (bool success,) = _to.call{value: _amount}("");
        require(success, "Transfer failed!");
        emit FundsSent(_to, _amount);
    }

    // Receive funds (this is the only declaration for receiving funds)
    receive() external payable {}

    // Fallback function
    fallback() external payable {}
}
