// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {SimpsVault} from "../src/SimpsVault.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RoomsTest is Test {
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
        vm.deal(simp3, 10000 ether);

        vm.startPrank(owner);
        simps.setFeeDestination(address(owner));
        simps.setProtocolFeePercent(50000000000000000);
        simps.setSubjectFeePercent(50000000000000000); 
        vm.stopPrank();       
    }

    /// @dev Tests the creation of a room with quadratic curve.
    function test_SimpsCreateRoomQuadratic() public {
        simps.createRoom(SimpsVault.Curves.Quadratic, 16000, 1, 0, 0);
        uint256 length = simps.getRoomsLength(address(this));
        assertEq(length, 1);
    }

    /// @dev Tests the creation of a room with linear curve.
    function test_SimpsCreateRoomLinear() public {
        simps.createRoom(SimpsVault.Curves.Linear, 16000, 1, 0, 0);
        uint256 length = simps.getRoomsLength(address(this));
        assertEq(length, 1);
    }

    /// @dev Tests the creation of a room with sigmoid curve.
    function test_SimpsCreateRoomSigmoid() public {
        simps.createRoom(SimpsVault.Curves.Linear, 16000, 1, 1 ether, 1000);
        uint256 length = simps.getRoomsLength(address(this));
        assertEq(length, 1);
    }

    /// @dev Tests the creation of a room with original curve.
    function test_SimpsCreateRoomOriginal() public {
        simps.createRoom(SimpsVault.Curves.Original, 16000, 1, 1 ether, 1000);
        uint256 length = simps.getRoomsLength(address(this));
        assertEq(length, 1);
    }

    /// @dev Tests the creation of a quadratic room and buying shares in one function
    function test_SimpsCreateRoomQuadraticAndBuyShare() public {
        vm.startPrank(simp1);

        uint256 supply = 1;
        uint256 amount = 1;
        uint256 steepness = 16000;
        uint256 floor = 0;
        int256 midPoint = 0;
        uint256 maxPrice = 0;

        uint256 price = simps.getPriceQuadratic(supply, amount, steepness, floor);

        uint256 protocolFee = price * 50000000000000000 / 1 ether;
        uint256 subjectFee = price * 50000000000000000 / 1 ether;

        uint256 room = simps.createRoomAndBuyShares{value: price + protocolFee + subjectFee}(SimpsVault.Curves.Quadratic, 1, steepness, floor, maxPrice, midPoint);

        // check room was created
        uint256 length = simps.getRoomsLength(address(simp1));
        assertEq(length, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp1);
        assertEq(balance, 2);

        vm.stopPrank();
    }

    /// @dev Tests the creation of a linear room and buying shares in one function
    function test_SimpsCreateRoomLinearAndBuyShare() public {
        vm.startPrank(simp1);

        uint256 supply = 1;
        uint256 amount = 1;
        uint256 steepness = 500;
        uint256 floor = 0;
        int256 midPoint = 0;
        uint256 maxPrice = 0;

        uint256 price = simps.getPriceLinear(supply, amount, steepness, floor);
        console2.log("buy; amount: %s, steepness: %s, floor: %s", amount, steepness, floor);
        console2.log("buy supply: %s, price = %e", supply, price);

        // uint256 protocolFee = price * 50000000000000000 / 1 ether;
        // uint256 subjectFee = price * 50000000000000000 / 1 ether;

        // uint256 room = simps.createRoomAndBuyShares{value: price + protocolFee + subjectFee}(SimpsVault.Curves.Linear, 1, steepness, floor, maxPrice, midPoint);

        // // check room was created
        // uint256 length = simps.getRoomsLength(address(simp1));
        // assertEq(length, 1);

        // // check shares balance
        // uint256 balance = simps.getSharesBalance(simp1, room, simp1);
        // assertEq(balance, 2);

        vm.stopPrank();
    }

    /// @dev Tests the creation of a linear room and buying shares in one function
    function test_SimpsCreateRoomSigmoidAndBuyShare() public {
        vm.startPrank(simp1);

        uint256 supply = 1;
        uint256 amount = 1;
        uint256 steepness = 16000;
        uint256 floor = 0;
        int256 midPoint = 0;
        uint256 maxPrice = 1 ether;

        uint256 price = simps.getPriceSigmoid(supply, amount, steepness, floor, maxPrice, midPoint);

        uint256 protocolFee = price * 50000000000000000 / 1 ether;
        uint256 subjectFee = price * 50000000000000000 / 1 ether;

        uint256 room = simps.createRoomAndBuyShares{value: price + protocolFee + subjectFee}(SimpsVault.Curves.Sigmoid, 1, steepness, floor, maxPrice, midPoint);

        // check room was created
        uint256 length = simps.getRoomsLength(address(simp1));
        assertEq(length, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp1);
        assertEq(balance, 2);

        vm.stopPrank();
    }

    /// @dev Tests the creation of a regular room and buying shares in one function
    function test_SimpsCreateRoomOriginalAndBuyShare() public {
        vm.startPrank(simp1);

        uint256 supply = 1;
        uint256 amount = 1;
        uint256 steepness = 16000;
        uint256 floor = 0;
        int256 midPoint = 0;
        uint256 maxPrice = 0;

        uint256 price = simps.getPriceOriginal(supply, amount);

        uint256 protocolFee = price * 50000000000000000 / 1 ether;
        uint256 subjectFee = price * 50000000000000000 / 1 ether;

        uint256 room = simps.createRoomAndBuyShares{value: price + protocolFee + subjectFee}(SimpsVault.Curves.Original, 1, steepness, floor, maxPrice, midPoint);

        // check room was created
        uint256 length = simps.getRoomsLength(address(simp1));
        assertEq(length, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp1);
        assertEq(balance, 2);

        vm.stopPrank();
    }


    /// @dev Tests the creation of a linear room and buying one share and selling one share
    function test_BuySellOneRoomLinear() public {
        vm.startPrank(simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Linear, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 1);

        simps.sellShares(simp1, room, 1);

        // check balance
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();
    }

    /// @dev Test selling too many shares
    function test_failSellTooManyShares() public {
        vm.startPrank(simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Linear, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 1);

        simps.sellShares(simp1, room, 1);

        vm.expectRevert();
        simps.sellShares(simp1, room, 1);

        // check balance
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();
    }

    /// @dev Test selling too many shares that you own
    function test_failSellTooManySharesAnotherUserOwns() public {
        vm.startPrank(simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Linear, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 1);

        vm.startPrank(simp3);

        price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        // check shares balance
        balance = simps.getSharesBalance(simp1, room, simp3);
        assertEq(balance, 2);
        

        simps.sellShares(simp1, room, 1);
        simps.sellShares(simp1, room, 1);
        vm.expectRevert();
        simps.sellShares(simp1, room, 1);

        // check balance
        balance = simps.getSharesBalance(simp1, room, simp3);
        assertEq(balance, 0);

        vm.stopPrank();
    }

    /// @dev Tests the creation of a quadratic room and buying one share and selling one share
    function test_BuySellOneRoomQuadratic() public {
        vm.startPrank(simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Quadratic, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 1);

        simps.sellShares(simp1, 0, 1);

        // check balance
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();
    }

    /// @dev Test selling zero amount of shares does not transfer any funds since quadratic curve results in floor price
    function test_SellZeroLinear() public {
        vm.startPrank(simp1);

        // ensure contract has funds
        vm.deal(address(simps), 100 ether);

        // steal `floor` amount of funds
        uint256 floor = address(simps).balance;
        uint256 room = simps.createRoom(SimpsVault.Curves.Linear, 16000, floor, 0, 0);

        uint256 balanceBefore = address(simp1).balance;
        simps.sellShares(simp1, 0, 0);
        uint256 balanceAfter = address(simp1).balance;
        assertEq(balanceAfter - balanceBefore, 0);

        vm.stopPrank();
    }

    /// @dev Test selling zero amount of shares does not transfer any funds since quadratic curve results in floor price
    function test_SellZeroQuadratic() public {
        vm.startPrank(simp1);

        // ensure contract has funds
        vm.deal(address(simps), 100 ether);

        // steal `floor` amount of funds
        uint256 floor = address(simps).balance;
        uint256 room = simps.createRoom(SimpsVault.Curves.Quadratic, 16000, floor, 0, 0);

        uint256 balanceBefore = address(simp1).balance;
        simps.sellShares(simp1, 0, 0);
        uint256 balanceAfter = address(simp1).balance;
        assertEq(balanceAfter - balanceBefore, 0);

        vm.stopPrank();
    }

    receive() external payable {
        console2.log("money received");
    }

    /// @dev Tests the creation of a sigmoid room and buying one share and selling one share
    function test_BuySellOneRoomSigmoid() public {
        vm.startPrank(simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Sigmoid, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 1);

        simps.sellShares(simp1, room, 1);

        // check balance
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();

    }

    // @dev Tests the creation of a room and transfering shares
    function test_Transfer() public {
        vm.startPrank(simp1);

        // create room
        uint256 room = simps.createRoom(SimpsVault.Curves.Linear, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        // buy one share
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        // check shares balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 1);

        // transfer share
        simps.transfer(address(simp3), address(simp1), room, 1);

        // check shares balance
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();

        vm.startPrank(simp3);
        // simp3 check shares balance
        balance = simps.getSharesBalance(simp1, room, simp3);
        assertEq(balance, 1);
        vm.stopPrank();
    }

    function test_SellRoomQuadraticBatchBuyLoopSell() public {
        uint256 amount = 20;

        vm.startPrank(simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Quadratic, 1200, 0, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);

        uint256 price = simps.getBuyPriceAfterFee(simp1, room, amount); 
        simps.buyShares{value: price}(simp1, room, amount);

        for (uint256 i = 0; i < amount; i++) {
            simps.sellShares(simp1, room, 1);
        }

        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        // uint256 simpsEthBalance = address(simps).balance;
        // assertEq(simpsEthBalance, 0);

        vm.stopPrank(); 
    }

    function test_SellRoomQuadraticLoopBuyBatchSell() public {
        uint256 amount = 50;

        vm.startPrank(simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Quadratic, 16000, 0, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);

        for (uint256 i = 0; i < amount; i++) {
            uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1); 
            simps.buyShares{value: price}(simp1, room, 1);
        }

        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, amount);

        simps.sellShares(simp1, room, amount);

        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        uint256 simpsEthBalance = address(simps).balance;
        assertEq(simpsEthBalance, 0);

        vm.stopPrank(); 
    }

    function test_SellRoomSigmoidBatchBuyLoopSell() public {
        uint256 amount = 100;

        vm.startPrank(simp1);
        uint256 room = simps.createRoom(SimpsVault.Curves.Sigmoid, 1200, 0, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);

        uint256 price = simps.getBuyPriceAfterFee(simp1, room, amount); 
        simps.buyShares{value: price}(simp1, room, amount);

        for (uint256 i = 0; i < amount; i++) {
            simps.sellShares(simp1, 0, 1);
        }

        uint256 simpsEthBalance = address(simps).balance;
        assertEq(simpsEthBalance, 0);

        vm.stopPrank(); 
    }

    function test_SharesSupplyBuyLinear() public {
        uint256 amount = 4;
        
        vm.startPrank(simp1);

        uint256 room = simps.createRoom(SimpsVault.Curves.Linear, 16000, 0, 0, 0);
        uint256 length = simps.getRoomsLength(simp1);
        assertEq(length, 1);

        uint256 price = simps.getBuyPriceAfterFee(simp1, room, amount); 
        simps.buyShares{value: price}(simp1, room, amount);

        uint256 supply = simps.getSharesSupply(simp1, room);
        assertEq(supply, amount + 1);
        
        vm.stopPrank();
    }

    function test_SharesBalanceBuyLinear() public {
        uint256 amount = 4;

        vm.startPrank(simp1);

        simps.createRoom(SimpsVault.Curves.Linear, 16000, 0, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        
        uint256 price = simps.getBuyPriceAfterFee(simp1, 0, amount); 
        simps.buyShares{value: price}(simp1, 0, amount);

        uint256 balance = simps.getSharesBalance(simp1, 0, simp2);
        assertEq(balance, amount);
        
        vm.stopPrank();   
    }

}