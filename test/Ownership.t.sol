// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {SimpsVault} from "../src/SimpsVault.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract OwnershipTest is Test {
    SimpsVault public simps;
    ERC1967Proxy proxy;
    address simp1 = address(0x1);
    address simp2 = address(0x2);
    address simp3 = address(0x3);
    address owner = address(0x4);

    /// @dev Sets up the initial state of the contract.
    function setUp() public {
        SimpsVault implementation = new SimpsVault();
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, owner));
        simps = SimpsVault(address(proxy));
        vm.deal(simp1, 10000 ether);
        vm.deal(simp2, 10000 ether);

        vm.startPrank(owner);
        simps.setFeeDestination(address(simp3));
        simps.setProtocolFeePercent(50000000000000000);
        simps.setSubjectFeePercent(50000000000000000); 
        vm.stopPrank();       
    }

    /// @dev Changes the protocol fee percent with not the owner
    function test_failChangeProtocolFee() public {
        vm.startPrank(simp1);
        vm.expectRevert();
        simps.setProtocolFeePercent(50000000000000000);
    }

    /// @dev Changes the protocol fee percent with the owner
    function test_ChangeProtocolFee() public {
        vm.startPrank(owner);
        simps.setProtocolFeePercent(20000000000000000);
    }

    /// @dev Changes the subject fee percent with not the owner
    function test_failChangeSubjectFee() public {
        vm.startPrank(simp1);
        vm.expectRevert();
        simps.setSubjectFeePercent(50000000000000000);
    }

    /// @dev Changes the subject fee percent with not the owner
    function test_ChangeSubjectFee() public {
        vm.startPrank(owner);
        simps.setSubjectFeePercent(20000000000000000);
    }

    /// @dev Changes the fee destination not the owner
    function test_failChangeDestinationAddress() public {
        vm.startPrank(simp2);
        vm.expectRevert();
        simps.setFeeDestination(address(simp3));
    }

    /// @dev Changes the fee destination not the owner
    function test_ChangeDestinationAddress() public {
        vm.startPrank(owner);
        simps.setFeeDestination(address(simp3));
    }

}