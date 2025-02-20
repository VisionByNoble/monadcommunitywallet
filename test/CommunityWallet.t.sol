// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/CommunityWallet.sol";

contract CommunityWalletTest is Test {
    CommunityWallet wallet;
    address owner = address(0x1);
    address member1 = address(0x2);
    address member2 = address(0x3);
    address nonMember = address(0x4);
    address recipient = address(0x5);

    function setUp() public {
        vm.prank(owner);
        wallet = new CommunityWallet();
        vm.deal(address(wallet), 10 ether); // Fund the wallet with 10 ETH
    }

    function test_InitialState() public view {
        assertEq(wallet.owner(), owner);
        assertTrue(wallet.members(owner));
        assertEq(wallet.getBalance(), 10 ether);
    }

    function test_AddMember() public {
        vm.prank(owner);
        wallet.addMember(member1);
        assertTrue(wallet.members(member1));
    }

    function test_RemoveMember() public {
        vm.startPrank(owner);
        wallet.addMember(member1);
        wallet.removeMember(member1);
        vm.stopPrank();
        assertFalse(wallet.members(member1));
    }

    function test_TransferOwnership() public {
        vm.prank(owner);
        wallet.transferOwnership(member1);

        vm.prank(member1);
        wallet.acceptOwnership();

        assertEq(wallet.owner(), member1);
        assertTrue(wallet.members(member1));
    }

    function test_SendMoney() public {
        vm.prank(owner);
        wallet.sendMoney(payable(recipient), 1 ether);

        assertEq(address(wallet).balance, 9 ether);
        assertEq(recipient.balance, 1 ether);
    }

    function test_OnlyMembersCanSendMoney() public {
        vm.prank(nonMember);
        vm.expectRevert("You're not a member!");
        wallet.sendMoney(payable(recipient), 1 ether);
    }

    function test_ReceiveFunds() public {
        vm.deal(member1, 2 ether);
        vm.prank(member1);
        (bool success,) = address(wallet).call{value: 2 ether}("");
        assertTrue(success);
        assertEq(wallet.getBalance(), 12 ether);
    }

    function test_ReentrancyGuard() public {
        // Deploy the malicious receiver
        MaliciousReceiver malicious = new MaliciousReceiver(address(wallet));

        // Add the malicious contract as a member
        vm.prank(owner);
        wallet.addMember(address(malicious));

        // Fund the wallet
        vm.deal(address(wallet), 2 ether);

        // Record initial balances
        uint256 initialWalletBalance = address(wallet).balance;
        uint256 initialMaliciousBalance = address(malicious).balance;

        // Call sendMoney and expect it to revert due to reentrancy
        vm.prank(owner);
        try wallet.sendMoney(payable(address(malicious)), 1 ether) {
            assertTrue(false, "Expected sendMoney to revert due to reentrancy");
        } catch {
            // Verify reentrancy was prevented: no funds were transferred
            assertEq(address(wallet).balance, initialWalletBalance, "Wallet balance should not change");
            assertEq(address(malicious).balance, initialMaliciousBalance, "Malicious balance should not change");
        }
    }
}

// Malicious contract to test reentrancy
contract MaliciousReceiver {
    CommunityWallet wallet;
    bool public reentrancyAttempted;

    constructor(address _wallet) {
        wallet = CommunityWallet(payable(_wallet));
    }

    receive() external payable {
        if (!reentrancyAttempted) {
            reentrancyAttempted = true;
            // Attempt reentrancy
            wallet.sendMoney(payable(address(this)), 0.5 ether);
        }
    }
}
