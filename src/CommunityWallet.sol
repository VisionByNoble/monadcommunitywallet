// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title CommunityWallet - A multi-member wallet for community fund management
/// @notice Allows members to send funds and the owner to manage membership and ownership
/// @dev Uses OpenZeppelin's ReentrancyGuard to prevent reentrancy attacks
contract CommunityWallet is ReentrancyGuard {
    /// @notice The current owner of the wallet
    address public owner;

    /// @notice Mapping of addresses to their membership status
    mapping(address => bool) public members;

    /// @notice Address nominated to become the new owner (two-step ownership transfer)
    address public pendingOwner;

    /// @notice Version of the contract for tracking updates
    string public constant VERSION = "1.0.0";

    // Events
    /// @notice Emitted when funds are sent from the wallet
    event FundsSent(address indexed to, uint256 amount);

    /// @notice Emitted when funds are received by the wallet
    event FundsReceived(address indexed from, uint256 amount);

    /// @notice Emitted when a new member is added
    event MemberAdded(address indexed member);

    /// @notice Emitted when a member is removed
    event MemberRemoved(address indexed member);

    /// @notice Emitted when ownership transfer is initiated
    event OwnershipTransferStarted(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when ownership is successfully transferred
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // Modifiers
    /// @notice Restricts function calls to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action!");
        _;
    }

    /// @notice Restricts function calls to registered members
    modifier onlyMembers() {
        require(members[msg.sender], "You're not a member!");
        _;
    }

    /// @notice Initializes the contract with the deployer as the owner and a member
    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
    }

    /// @notice Adds a new member to the wallet
    /// @param _member The address to add as a member
    function addMember(address _member) public onlyOwner {
        require(_member != address(0), "Cannot add zero address!");
        require(!members[_member], "Member already added!");
        members[_member] = true;
        emit MemberAdded(_member);
    }

    /// @notice Removes an existing member from the wallet
    /// @param _member The address to remove as a member
    function removeMember(address _member) public onlyOwner {
        require(_member != address(0), "Cannot remove zero address!");
        require(members[_member], "Address is not a member!");
        require(_member != owner, "Cannot remove owner!");
        members[_member] = false;
        emit MemberRemoved(_member);
    }

    /// @notice Initiates a two-step ownership transfer
    /// @param newOwner The address nominated to become the new owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address!");
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    /// @notice Completes the ownership transfer, callable only by the pending owner
    function acceptOwnership() public {
        require(msg.sender == pendingOwner, "Only pending owner can accept!");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        members[pendingOwner] = true; // Ensure new owner is a member
        pendingOwner = address(0);
    }

    /// @notice Sends funds from the wallet to a specified address
    /// @param _to The recipient address
    /// @param _amount The amount of ETH to send (in wei)
    function sendMoney(address payable _to, uint256 _amount) public onlyMembers nonReentrant {
        require(_to != address(0), "Cannot send to zero address!");
        require(address(this).balance >= _amount, "Insufficient balance in wallet!");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed!");
        emit FundsSent(_to, _amount);
    }

    /// @notice Returns the current balance of the wallet
    /// @return The balance in wei
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Allows the contract to receive ETH
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    /// @notice Fallback function to receive ETH
    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
}