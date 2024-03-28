// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {SimpsVault} from "../src/SimpsVault.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract FuzzBuySellLinear is Test {
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
        vm.deal(simp1, 100000 ether);
        vm.deal(simp2, 100000 ether);

        vm.startPrank(owner);
        simps.setFeeDestination(address(simp3));
        simps.setProtocolFeePercent(50000000000000000);
        simps.setSubjectFeePercent(50000000000000000); 
        vm.stopPrank();       
    }

    /// @dev Tests the creation of a linear room, loop buying shares, and loop selling
    function test_fuzzLoopBuyLoopSellSharesLinear(uint256 amount, uint256 steepness) public {
        amount = bound(amount, 1, 1000);
        steepness = bound(steepness, 1_000, 10_000_001);

        vm.startPrank(simp1, simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Linear, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2, simp2);

        // loop buy shares
        for (uint256 i = 0; i < amount; i++) {
            uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
            simps.buyShares{value: price}(simp1, room, 1);
        }

        // check balance after buy
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, amount);

        // loop sell shares
        for (uint256 i = 0; i < amount; i++) {
            simps.sellShares(simp1, room, 1);
        }

        // check balance after sell
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        // check token contract balance
        uint256 simpsEthBalance = address(simps).balance;
        assertEq(simpsEthBalance, 0);

        // check shares supply
        uint256 supply = simps.getSharesSupply(simp1, 0);
        assertEq(supply, 1);

        vm.stopPrank();
    }

    /// @dev Tests the creation of a linear room, loop buying shares, and batch selling
    function test_fuzzLoopBuyBatchSellSharesLinear(uint256 amount, uint256 steepness) public {
        amount = bound(amount, 1, 1000);
        steepness = bound(steepness, 1000, 100000);

        vm.startPrank(simp1, simp1);
        // create room
        uint256 room = simps.createRoom(SimpsVault.Curves.Linear, 16000, 0, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2, simp2);

        // loop buy shares
        for (uint256 i = 0; i < amount; i++) {
            uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1); 
            simps.buyShares{value: price}(simp1, room, 1);
        }

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, amount);

        // batch sell shares
        simps.sellShares(simp1, room, amount);

        // check shares balance after sell
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        // check token contract eth balance
        uint256 simpsEthBalance = address(simps).balance;
        assertEq(simpsEthBalance, 0);

        vm.stopPrank(); 
    }

    /// @dev Tests the creation of a linear room, batch buying shares, and loop selling
    function test_fuzzBatchBuyLoopSellSharesLinear(uint256 amount, uint256 steepness) public {
        amount = bound(amount, 1, 1000);
        steepness = bound(steepness, 1000, 100000);

        vm.startPrank(simp1, simp1);
        // create room
        uint256 room = simps.createRoom(SimpsVault.Curves.Linear, 16000, 0, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2, simp2);

        // batch buy shares
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, amount); 
        simps.buyShares{value: price}(simp1, room, amount);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, amount);

        // loop sell shares
        for (uint256 i = 0; i < amount; i++) {
            simps.sellShares(simp1, room, 1);
        }

        // check shares balance after sell
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        // check token contract eth balance
        uint256 simpsEthBalance = address(simps).balance;
        assertEq(simpsEthBalance, 0);

        vm.stopPrank(); 
    }

}