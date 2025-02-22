// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title CommunityWallet - A multi-member wallet for community fund management
/// @notice Allows donations in ETH and $MON, and only the owner can send funds out
/// @dev Uses OpenZeppelin's ReentrancyGuard and SafeERC20 for secure transactions
contract CommunityWallet is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The current owner of the wallet (immutable for gas optimization)
    address public immutable owner;

    /// @notice Address nominated to become the new owner (two-step ownership transfer)
    address public pendingOwner;

    /// @notice Version of the contract for tracking updates
    string public constant VERSION = "1.0.1";

    // Custom Errors
    error OnlyOwner();
    error ZeroAddress();
    error InsufficientBalance();
    error TransferFailed();
    error InvalidAmount();

    // Events
    event FundsSent(address indexed to, uint256 amount);
    event FundsReceived(address indexed from, uint256 amount);
    event TokensSent(address indexed token, address indexed to, uint256 amount);
    event TokensReceived(address indexed token, address indexed from, uint256 amount);
    event OwnershipTransferStarted(address indexed oldOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    /// @notice Initializes the contract with the deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    /// @notice Initiates a two-step ownership transfer
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    /// @notice Completes the ownership transfer, callable only by the pending owner
    function acceptOwnership() public {
        if (msg.sender != pendingOwner) revert OnlyOwner();
        emit OwnershipTransferred(owner, pendingOwner);
        pendingOwner = address(0);
    }

    /// @notice Sends ETH from the wallet to a specified address
    function sendETH(address payable _to, uint256 _amount) public onlyOwner nonReentrant {
        if (_to == address(0)) revert ZeroAddress();
        if (address(this).balance < _amount) revert InsufficientBalance();
        (bool success,) = _to.call{value: _amount}("");
        if (!success) revert TransferFailed();
        emit FundsSent(_to, _amount);
    }

    /// @notice Sends ERC-20 tokens from the wallet to a specified address using SafeERC20
    function sendTokens(address _token, address _to, uint256 _amount) public onlyOwner nonReentrant {
        if (_to == address(0)) revert ZeroAddress();
        if (IERC20(_token).balanceOf(address(this)) < _amount) revert InsufficientBalance();
        IERC20(_token).safeTransfer(_to, _amount);
        emit TokensSent(_token, _to, _amount);
    }

    /// @notice Allows users to donate ERC-20 tokens to the contract
    function donateTokens(address _token, uint256 _amount) public {
        if (_token == address(0)) revert ZeroAddress();
        if (_amount == 0) revert InvalidAmount();
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit TokensReceived(_token, msg.sender, _amount);
    }

    /// @notice Returns the current ETH balance of the wallet
    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the current balance of an ERC-20 token in the wallet
    function getTokenBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
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
