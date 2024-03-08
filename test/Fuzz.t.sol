// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {SimpsVault} from "../src/SimpsVault.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract FuzzTest is Test {
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
        vm.deal(simp1, 10000000000 ether);
        vm.deal(simp2, 10000000000 ether);

        vm.startPrank(owner);
        simps.setFeeDestination(address(simp3));
        simps.setProtocolFeePercent(50000000000000000);
        simps.setSubjectFeePercent(50000000000000000); 
        vm.stopPrank();
    }

    //// @dev Tests the creation of a quadratic room and buying shares in one function
    function test_fuzzSimpsCreateRoomQuadraticAndBuyShare(uint256 amount) public {
        amount = bound(amount, 1, 10_000);
        vm.startPrank(simp1);

        uint256 supply = 1;
        uint256 steepness = 16000;
        uint256 floor = 0;
        int256 midPoint = 0;
        uint256 maxPrice = 0;

        uint256 price = simps.getPriceQuadratic(supply, amount, steepness, floor);

        uint256 protocolFee = price * 50000000000000000 / 1 ether;
        uint256 subjectFee = price * 50000000000000000 / 1 ether;

        uint256 room = simps.createRoomAndBuyShares{value: price + protocolFee + subjectFee}(SimpsVault.Curves.Quadratic, amount, steepness, floor, maxPrice, midPoint);

        // check room was created
        uint256 length = simps.getRoomsLength(address(simp1));
        assertEq(length, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp1);
        assertEq(balance, amount + 1);

        vm.stopPrank();
    }

    //// @dev Tests the creation of a quadratic room and buying shares in one function
    function test_fuzzSimpsCreateRoomLinearAndBuyShare(uint256 amount) public {
        amount = bound(amount, 1, 10_000);
        vm.startPrank(simp1);

        uint256 supply = 1;
        uint256 steepness = 16000;
        uint256 floor = 0;
        int256 midPoint = 0;
        uint256 maxPrice = 0;

        uint256 price = simps.getPriceLinear(supply, amount, steepness, floor);

        uint256 protocolFee = price * 50000000000000000 / 1 ether;
        uint256 subjectFee = price * 50000000000000000 / 1 ether;

        uint256 room = simps.createRoomAndBuyShares{value: price + protocolFee + subjectFee}(SimpsVault.Curves.Linear, amount, steepness, floor, maxPrice, midPoint);

        // check room was created
        uint256 length = simps.getRoomsLength(address(simp1));
        assertEq(length, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp1);
        assertEq(balance, amount + 1);

        vm.stopPrank();
    }

    //// @dev Tests the creation of a original room and buying shares in one function
    function test_fuzzSimpsCreateRoomOriginalAndBuyShare(uint256 amount) public {
        amount = bound(amount, 1, 10_000);
        vm.startPrank(simp1);

        uint256 supply = 1;
        uint256 steepness = 16000;
        uint256 floor = 0;
        int256 midPoint = 0;
        uint256 maxPrice = 0;

        uint256 price = simps.getPriceOriginal(supply, amount);

        uint256 protocolFee = price * 50000000000000000 / 1 ether;
        uint256 subjectFee = price * 50000000000000000 / 1 ether;

        uint256 room = simps.createRoomAndBuyShares{value: price + protocolFee + subjectFee}(SimpsVault.Curves.Original, amount, steepness, floor, maxPrice, midPoint);

        // check room was created
        uint256 length = simps.getRoomsLength(address(simp1));
        assertEq(length, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp1);
        assertEq(balance, amount + 1);

        vm.stopPrank();
    }

    //// @dev Tests the creation of a sigmoid room and buying shares in one function
    function test_fuzzSimpsCreateRoomSigmoidAndBuyShare(uint256 amount) public {
        amount = bound(amount, 1, 200);
        vm.startPrank(simp1);

        uint256 supply = 1;
        uint256 steepness = 16000;
        uint256 floor = 0;
        int256 midPoint = 0;
        uint256 maxPrice = 0;

        uint256 price = simps.getPriceSigmoid(supply, amount, steepness, floor, maxPrice, midPoint);

        uint256 protocolFee = price * 50000000000000000 / 1 ether;
        uint256 subjectFee = price * 50000000000000000 / 1 ether;

        uint256 room = simps.createRoomAndBuyShares{value: price + protocolFee + subjectFee}(SimpsVault.Curves.Sigmoid, amount, steepness, floor, maxPrice, midPoint);

        // check room was created
        uint256 length = simps.getRoomsLength(address(simp1));
        assertEq(length, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp1);
        assertEq(balance, amount + 1);

        vm.stopPrank();
    }

    //// @dev Tests the creation of a linear room, buying share, and selling share
    function test_fuzzLinearBuySell(uint256 amount) public {
        amount = bound(amount, 1, 10_000);
        vm.startPrank(simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Linear, 1600, 1, 0.1 ether, 1000);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, amount);
        simps.buyShares{value: price}(simp1, room, amount);

        // check balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, amount);

        simps.sellShares(simp1, room, amount);

        // check balance
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();
    }

    //// @dev Tests the creation of a quadratic room, buying share, and selling share
    function test_fuzzQuadraticBuySell(uint256 amount) public {
        amount = bound(amount, 1, 10_000);

        vm.startPrank(simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Quadratic, 1600, 1, 0.4 ether, 1000);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, amount);
        simps.buyShares{value: price}(simp1, room, amount);

        // check balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, amount);

        simps.sellShares(simp1, room, amount);

        // check balance
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();
    }

    //// @dev Tests the creation of a sigmoid room, buying share, and selling share
    function test_fuzzSigmoidBuySell(uint256 amount) public {
        amount = bound(amount, 1, 10);

        vm.startPrank(simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Sigmoid, 1600, 1, 0.5 ether, 10000);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, amount);
        simps.buyShares{value: price}(simp1, room, amount);

        // check balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, amount);

        simps.sellShares(simp1, room, amount);

        // check balance
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();

    }

}