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
    MockERC20 monToken;
    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    function setUp() public {
        // Deploy mock MON token first
        monToken = new MockERC20("Mock MON", "MON");

        // Deploy wallet with mock MON token address as owner
        vm.prank(owner);
        wallet = new CommunityWallet(address(monToken));

        // Mint tokens to user1 for testing
        monToken.mint(user1, 1000 ether);
    }

    // Test that the owner is the one who deployed the contract
    function testOwnerInitialization() public view {
        assertEq(wallet.owner(), owner, "Owner should be the deployer");
    }

    // Test that the MON token address is set correctly
    function testMonTokenInitialization() public view {
        assertEq(wallet.MON_TOKEN(), address(monToken), "MON token address should be set correctly");
    }

    // Test ETH send restricted to only the contract
    function testSendETHRestricted() public {
        vm.deal(address(wallet), 1 ether);

        // Owner tries to send ETH
        vm.prank(owner);
        vm.expectRevert(CommunityWallet.OnlyContractCanSend.selector);
        wallet.sendETH(payable(user1), 0.5 ether);
    }

    // Test token send restricted to only the contract
    function testSendTokensRestricted() public {
        vm.prank(owner);
        vm.expectRevert(CommunityWallet.OnlyContractCanSend.selector);
        wallet.sendTokens(address(monToken), user2, 300 ether);
    }

    // Test donating tokens to the contract
    function testDonateTokens() public {
        vm.prank(user1);
        monToken.approve(address(wallet), 500 ether);
        vm.prank(user1);
        wallet.donateTokens(address(monToken), 500 ether);

        // Validate donation
        assertEq(monToken.balanceOf(address(wallet)), 500 ether, "Wallet should have 500 tokens");
    }

    // Test sending ETH or tokens to zero address
    function testCannotSendToZeroAddress() public {
        // Test sending ETH to zero address by contract (should fail with OnlyContractCanSend())
        vm.prank(address(wallet)); // Contract itself, not the owner
        vm.expectRevert(CommunityWallet.ZeroAddress.selector); // Expect ZeroAddress error
        wallet.sendETH(payable(address(0)), 0.1 ether);

        // Test sending tokens to zero address by contract (should fail with OnlyContractCanSend())
        vm.prank(address(wallet)); // Contract itself, not the owner
        vm.expectRevert(CommunityWallet.ZeroAddress.selector); // Expect ZeroAddress error
        wallet.sendTokens(address(monToken), address(0), 100 ether);
    }

    // Test that zero tokens cannot be donated
    function testCannotDonateZeroTokens() public {
        vm.prank(user1);
        vm.expectRevert(CommunityWallet.InvalidAmount.selector); // Expect custom error
        wallet.donateTokens(address(monToken), 0);
    }

    // Test MON token specific functions
    function testMonTokenFunctions() public {
        // Test depositMON
        vm.prank(user1);
        monToken.approve(address(wallet), 100 ether);
        vm.prank(user1);
        wallet.depositMON(100 ether);
        assertEq(monToken.balanceOf(address(wallet)), 100 ether, "Wallet should have 100 MON tokens");

        // Test sendMON (should fail for non-contract caller)
        vm.prank(owner);
        vm.expectRevert(CommunityWallet.OnlyContractCanSend.selector);
        wallet.sendMON(user2, 50 ether);

        // Test getMONBalance
        assertEq(wallet.getMONBalance(), 100 ether, "MON balance should be 100 tokens");
    }
}
