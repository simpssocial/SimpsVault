// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/SimpsVault.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";

contract DeployProxy is Script {
    function run() public {

        address _implementation = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
        vm.startBroadcast();

        // Encode the initializer function call
        bytes memory data = abi.encodeWithSelector(
            SimpsVault(_implementation).initialize.selector,
            msg.sender // Initial owner/admin of the contract
        );

        // Deploy the proxy contract with the implementation address and initializer
        ERC1967Proxy proxy = new ERC1967Proxy(_implementation, data);

        vm.stopBroadcast();
        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));

    }
}