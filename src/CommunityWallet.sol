// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title CommunityWallet - A decentralized wallet for managing community funds
/// @notice Allows donations in ETH and ERC-20 tokens. Only the contract itself can send funds out.
/// @dev Uses OpenZeppelin's ReentrancyGuard for security and SafeERC20 for safe token transfers.
contract CommunityWallet is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Address of the wallet's owner (immutable to save gas)
    address public owner;

    /// @notice Address nominated for ownership transfer (two-step process)
    address public pendingOwner;

    /// @notice Version identifier for tracking contract updates
    string public constant VERSION = "1.0.2";

    // Custom Errors (Saves gas compared to require() strings)
    error OnlyOwner();
    error ZeroAddress();
    error InsufficientBalance();
    error TransferFailed();
    error InvalidAmount();
    error OnlyContractCanSend();

    // Events (For better tracking on-chain)
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

    modifier onlyContract() {
        if (msg.sender != address(this)) revert OnlyContractCanSend();
        _;
    }

    /// @notice Contract is deployed with the sender as the owner
    constructor() {
        owner = msg.sender;
    }

    /// @notice Initiates the ownership transfer process to a new owner
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    /// @notice Completes the ownership transfer process
    function acceptOwnership() public {
        address oldOwner = owner;
        if (msg.sender != pendingOwner) revert OnlyOwner();
        owner = pendingOwner;
        emit OwnershipTransferred(oldOwner, msg.sender);
        pendingOwner = address(0);
    }

    // Add checks to prevent sending to zero address
    function sendETHCheck(address payable to, uint256 amount) public {
        if (to == address(0)) {
            revert ZeroAddress();
        }
        if (msg.sender != address(this)) {
            revert OnlyContractCanSend();
        }
        to.transfer(amount);
    }

    function sendTokensCheck(address token, address to, uint256 amount) public {
        if (to == address(0)) {
            revert ZeroAddress();
        }
        if (msg.sender != address(this)) {
            revert OnlyContractCanSend();
        }
        IERC20(token).transfer(to, amount);
    }

    /// @notice Sends ETH from the wallet, callable only by the contract itself
    function sendETH(address payable _to, uint256 _amount) public onlyContract nonReentrant {
        if (_to == address(0)) revert ZeroAddress(); // Zero address check first
        if (address(this).balance < _amount) revert InsufficientBalance();

        (bool success,) = _to.call{value: _amount}("");
        if (!success) revert TransferFailed();

        emit FundsSent(_to, _amount);
    }

    /// @notice Sends ERC-20 tokens from the wallet, callable only by the contract itself
    function sendTokens(address _token, address _to, uint256 _amount) public onlyContract nonReentrant {
        if (_to == address(0)) revert ZeroAddress(); // Zero address check first
        if (IERC20(_token).balanceOf(address(this)) < _amount) revert InsufficientBalance();

        IERC20(_token).safeTransfer(_to, _amount);
        emit TokensSent(_token, _to, _amount);
    }

    /// @notice Allows users to donate ERC-20 tokens to the contract
    function donateTokens(address _token, uint256 _amount) public {
        if (_token == address(0)) revert ZeroAddress();
        if (_amount == 0) revert InvalidAmount();

        // Replacing safeTransferFrom with transfer to save gas
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit TokensReceived(_token, msg.sender, _amount);
    }

    /// @notice Returns the ETH balance of the wallet
    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the balance of an ERC-20 token in the wallet
    function getTokenBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /// @notice Allows the contract to receive ETH donations
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    /// @notice Fallback function to receive ETH
    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
}
