// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/CommunityWallet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC-20 token for testing
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract CommunityWalletTest is Test {
    CommunityWallet wallet;
    MockERC20 token;
    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    function setUp() public {
        vm.prank(owner);
        wallet = new CommunityWallet();

        // Deploy a mock ERC-20 token
        token = new MockERC20("MockToken", "MTK");
        token.mint(user1, 1000 ether); // Mint tokens to user1 for testing
    }

    function testOwnerInitialization() public view {
        assertEq(wallet.owner(), owner, "Owner should be the deployer");
    }

    function testSendETH() public {
        // Fund the wallet
        vm.deal(address(wallet), 1 ether);

        // Send ETH
        vm.prank(owner);
        wallet.sendETH(payable(user1), 0.5 ether);

        assertEq(user1.balance, 0.5 ether, "User1 should receive 0.5 ETH");
        assertEq(address(wallet).balance, 0.5 ether, "Wallet should have 0.5 ETH left");
    }

    function testSendTokens() public {
        // Donate tokens to the wallet
        vm.prank(user1);
        token.approve(address(wallet), 500 ether);
        vm.prank(user1);
        wallet.donateTokens(address(token), 500 ether);

        // Send tokens
        vm.prank(owner);
        wallet.sendTokens(address(token), user2, 300 ether);

        assertEq(token.balanceOf(user2), 300 ether, "User2 should receive 300 tokens");
        assertEq(token.balanceOf(address(wallet)), 200 ether, "Wallet should have 200 tokens left");
    }

    function testDonateTokens() public {
        // Approve and donate tokens
        vm.prank(user1);
        token.approve(address(wallet), 500 ether);
        vm.prank(user1);
        wallet.donateTokens(address(token), 500 ether);

        assertEq(token.balanceOf(address(wallet)), 500 ether, "Wallet should have 500 tokens");
    }

    function testOnlyOwnerCanSendETH() public {
        vm.prank(user1);
        vm.expectRevert(CommunityWallet.OnlyOwner.selector); // Expect custom error
        wallet.sendETH(payable(user2), 0.1 ether);
    }

    function testOnlyOwnerCanSendTokens() public {
        vm.prank(user1);
        vm.expectRevert(CommunityWallet.OnlyOwner.selector); // Expect custom error
        wallet.sendTokens(address(token), user2, 100 ether);
    }

    function testCannotSendToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(CommunityWallet.ZeroAddress.selector); // Expect custom error
        wallet.sendETH(payable(address(0)), 0.1 ether);

        vm.prank(owner);
        vm.expectRevert(CommunityWallet.ZeroAddress.selector); // Expect custom error
        wallet.sendTokens(address(token), address(0), 100 ether);
    }

    function testCannotDonateZeroTokens() public {
        vm.prank(user1);
        vm.expectRevert(CommunityWallet.InvalidAmount.selector); // Expect custom error
        wallet.donateTokens(address(token), 0);
    }
}