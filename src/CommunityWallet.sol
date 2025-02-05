// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract CommunityWallet {
    // The address of the person who created the wallet (that's you!)
    address public owner;

    // A list of all the people who can use the wallet
    mapping(address => bool) public members;

    // Event to log when money is sent
    event MoneySent(address indexed to, uint256 amount);

    // Constructor: This runs once when the contract is created
    constructor() {
        owner = msg.sender; // You're the owner!
        members[msg.sender] = true; // You're also a member!
    }

    // Only the owner can add new members
    function addMember(address newMember) public {
        require(msg.sender == owner, "Only the owner can add members!");
        members[newMember] = true;
    }

    // Only members can send money from the wallet
    function sendMoney(address payable to, uint256 amount) public {
        require(members[msg.sender], "You're not a member!");
        require(address(this).balance >= amount, "Not enough money in the wallet!");

        to.transfer(amount); // Send the money
        emit MoneySent(to, amount); // Log the transaction
    }

    // Anyone can donate money to the wallet
    function donate() public payable {
        // The money is automatically added to the wallet
    }

    // Check the balance of the wallet
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}