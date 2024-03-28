// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Simps} from "../src/SimpsToken.sol";

contract TokenTest is Test {
    Simps public token;

    address simp1 = address(0x1);
    address simp2 = address(0x2);
    address owner = address(0x4);

    /// @dev Sets up the initial state of the contract.
    function setUp() public {
        vm.prank(owner);
        token = new Simps("SIMPS token", "SIMPS", 18);
        vm.deal(simp1, 100 ether);
        vm.deal(simp2, 100 ether);
    }

    function test_Balance() public {
        assertEq(token.balanceOf(simp1), 0);
        assertEq(token.balanceOf(simp2), 0);
        assertEq(token.balanceOf(owner), 1000 ether);
    }
}