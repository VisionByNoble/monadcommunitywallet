// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CommunityWallet is ReentrancyGuard {
    address public owner;
    mapping(address => bool) public members;
    address public pendingOwner;

    event FundsSent(address indexed to, uint256 amount);
    event FundsReceived(address indexed from, uint256 amount);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event OwnershipTransferStarted(address indexed oldOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action!");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "You're not a member!");
        _;
    }

    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
    }

    function addMember(address _member) public onlyOwner {
        require(_member != address(0), "Cannot add zero address!");
        require(!members[_member], "Member already added!");
        members[_member] = true;
        emit MemberAdded(_member);
    }

    function removeMember(address _member) public onlyOwner {
        require(_member != address(0), "Cannot remove zero address!");
        require(members[_member], "Address is not a member!");
        require(_member != owner, "Cannot remove owner!");
        members[_member] = false;
        emit MemberRemoved(_member);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address!");
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    function acceptOwnership() public {
        require(msg.sender == pendingOwner, "Only pending owner can accept!");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        members[pendingOwner] = true;
        pendingOwner = address(0);
    }

    function sendMoney(address payable _to, uint256 _amount) public onlyMembers nonReentrant {
        require(_to != address(0), "Cannot send to zero address!");
        require(address(this).balance >= _amount, "Insufficient balance in wallet");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed!");
        emit FundsSent(_to, _amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
}