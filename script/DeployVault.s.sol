// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/SimpsVault.sol";
import "forge-std/Script.sol";

contract DeployVaultImp is Script {
    function run() public {
        vm.startBroadcast();

        SimpsVault implementation = new SimpsVault();

        vm.stopBroadcast();

        console.log("Vault Implementation Address:", address(implementation));
    }
}