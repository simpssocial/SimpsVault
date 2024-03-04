// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Simps} from "../src/Simps.sol";

contract FuzzTest is Test {
    Simps public simps;
    address simp1 = address(0x1);
    address simp2 = address(0x2);
    address simp3 = address(0x3);

    function setUp() public {
        simps = new Simps();
        vm.deal(simp1, 100 ether);
        vm.deal(simp2, 1000000000000 ether);

        simps.setFeeDestination(address(simp3));
        simps.setProtocolFeePercent(50000000000000000);
        simps.setSubjectFeePercent(50000000000000000);        
    }

    function test_fuzzLinearBuySell(uint16 amount) public {
        vm.startPrank(simp1);
        simps.createRoom(Simps.Curves.Linear, 1600);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, 0, amount);
        simps.buyShares{value: price}(simp1, 0, amount);

        // check balance
        uint256 balance = simps.getSharesBalance(simp1, 0, simp2);
        assertEq(balance, amount);

        simps.sellShares(simp1, 0, amount);

        // check balance
        balance = simps.getSharesBalance(simp1, 0, simp2);
        assertEq(balance, 0);

        vm.stopPrank();
    }

    function test_fuzzQuadraticBuySell(uint16 amount) public {
        vm.startPrank(simp1);
        simps.createRoom(Simps.Curves.Quadratic, 1600);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, 0, amount);
        simps.buyShares{value: price}(simp1, 0, amount);

        // check balance
        uint256 balance = simps.getSharesBalance(simp1, 0, simp2);
        assertEq(balance, amount);

        simps.sellShares(simp1, 0, amount);

        // check balance
        balance = simps.getSharesBalance(simp1, 0, simp2);
        assertEq(balance, 0);

        vm.stopPrank();
    }

    function test_fuzzSigmoidBuySell(uint16 amount) public {
        vm.assume(amount < 100);
        vm.startPrank(simp1);
        simps.createRoom(Simps.Curves.Sigmoid, 1600);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, 0, amount);
        simps.buyShares{value: price}(simp1, 0, amount);

        // check balance
        uint256 balance = simps.getSharesBalance(simp1, 0, simp2);
        assertEq(balance, amount);

        simps.sellShares(simp1, 0, amount);

        // check balance
        balance = simps.getSharesBalance(simp1, 0, simp2);
        assertEq(balance, 0);

        vm.stopPrank();
    }

    /*
    function test_fuzzFriendSell(uint256 supply, uint256 amount) public {
        supply = bound(supply, 1, 1e18);
        amount = bound(amount, 1, 1e18);
        vm.assume(supply > amount);
        uint256 result = simps.getPriceFriend(supply - amount, amount);
        assertGe(result, 0);
    }

    function test_fuzzQuadraticBuy(uint256 supply, uint256 amount) public {
        supply = bound(supply, 1, 1e18);
        amount = bound(amount, 1, 1e18);
        uint256 result = simps.getPriceQuadratic(supply, amount, 16000);
        assertGt(result, 0);
    }

    function test_fuzzLinearBuy(uint256 supply, uint256 amount) public {
        supply = bound(supply, 1, 1e18);
        amount = bound(amount, 1, 1e18);
        uint256 result = simps.getPriceLinear(supply, amount, 16000);
        assertGt(result, 0);
    }
    */
}