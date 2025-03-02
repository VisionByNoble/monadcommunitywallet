// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MonToken.sol";
import "../src/CommunityWallet.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MonToken first
        MonToken monToken = new MonToken();
        console.log("MonToken deployed at:", address(monToken));

        // Deploy CommunityWallet with MonToken address
        CommunityWallet wallet = new CommunityWallet(address(monToken));
        console.log("CommunityWallet deployed at:", address(wallet));

        vm.stopBroadcast();
    }
}
