// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/CommunityWallet.sol";

contract CommunityWalletTest is Test {
    CommunityWallet wallet;
    address owner = address(0x123);
    address member = address(0x456);
    address stranger = address(0x789);

    function setUp() public {
        vm.prank(owner); // Pretend to be the owner
        wallet = new CommunityWallet();
    }

    function testAddMember() public {
        vm.prank(owner); // Pretend to be the owner
        wallet.addMember(member);

        assertTrue(wallet.members(member), "Member should be added!");
    }

    function testSendMoney() public {
        vm.prank(owner); // Pretend to be the owner
        wallet.addMember(member);

        vm.deal(address(wallet), 100 ether); // Give the wallet some money
        vm.prank(member); // Pretend to be the member
        wallet.sendMoney(payable(stranger), 50 ether);

        assertEq(stranger.balance, 50 ether, "Stranger should receive 50 ether!");
    }

    function testDonate() public {
        vm.deal(owner, 100 ether); // Give the owner some money
        vm.prank(owner); // Pretend to be the owner
        wallet.donate{value: 50 ether}();

        assertEq(address(wallet).balance, 50 ether, "Wallet should have 50 ether!");
    }
}