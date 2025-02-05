// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract CommunityWallet {
    address public owner;
    mapping(address => bool) public members;

    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event FundsSent(address indexed to, uint256 amount);
    event FundsReceived(address indexed from, uint256 amount);

    constructor() {
        owner = msg.sender;
        members[msg.sender] = true; // Owner is a member by default
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action!");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "You're not a member!");
        _;
    }

    function addMember(address _member) public onlyOwner {
        require(!members[_member], "Member already added!");
        members[_member] = true;
        emit MemberAdded(_member);
    }

    function removeMember(address _member) public onlyOwner {
        require(members[_member], "Address is not a member!");
        members[_member] = false;
        emit MemberRemoved(_member);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address!");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function sendMoney(address payable _to, uint256 _amount) public onlyMembers {
        require(address(this).balance >= _amount, "Insufficient balance in wallet");
        _to.transfer(_amount);
        emit FundsSent(_to, _amount);
    }

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
}
