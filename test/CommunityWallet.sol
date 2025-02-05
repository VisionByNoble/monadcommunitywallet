// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

contract CommunityWallet {
    address public owner;

    mapping(address => bool) public members;

    constructor() {
        owner = msg.sender;
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
        members[_member] = true;
    }

    function removeMember(address _member) public onlyOwner {
        members[_member] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function sendMoney(address payable _to, uint256 _amount) public onlyMembers {
        require(address(this).balance >= _amount, "Insufficient balance in wallet");

        _to.transfer(_amount);
    }

    receive() external payable {}
}
