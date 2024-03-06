// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {Simps} from "../src/Simps.sol";

contract SimpsTest is Test {
    Simps public simps;
    address simp1 = address(0x1);
    address simp2 = address(0x2);
    address simp3 = address(0x3);

    function setUp() public {
        simps = new Simps();
        vm.deal(simp1, 10000 ether);
        vm.deal(simp2, 10000 ether);

        simps.setFeeDestination(address(simp3));
        simps.setProtocolFeePercent(50000000000000000);
        simps.setSubjectFeePercent(50000000000000000);        
    }

    function test_BuyRoomInvalid() public {
        simps.createRoom(Simps.Curves.Quadratic, 16000, 1, 0, 0);
        uint256 length = simps.getRoomsLength(address(this));
        assertEq(length, 1);
    }

    function test_SimpsCreateRoomQuadratic() public {
        simps.createRoom(Simps.Curves.Quadratic, 16000, 1, 0, 0);
        uint256 length = simps.getRoomsLength(address(this));
        assertEq(length, 1);
    }

    function test_SimpsCreateRoomLinear() public {
        simps.createRoom(Simps.Curves.Linear, 16000, 1, 0, 0);
        uint256 length = simps.getRoomsLength(address(this));
        assertEq(length, 1);
    }

    function test_SimpsCreateRoomSigmoid() public {
        simps.createRoom(Simps.Curves.Linear, 16000, 1, 1 ether, 1000);
        uint256 length = simps.getRoomsLength(address(this));
        assertEq(length, 1);
    }

    function test_SimpsCreateRoomAndBuyShare() public {
        vm.startPrank(simp1);

        uint256 supply = 1;
        uint256 amount = 1;
        uint256 steepness = 16000;
        uint256 floor = 0;
        int256 currentLimit = 0;
        uint256 maxPrice = 0;

        uint256 price = simps.getPriceQuadratic(supply, amount, steepness, floor);

        uint256 protocolFee = price * 50000000000000000 / 1 ether;
        uint256 subjectFee = price * 50000000000000000 / 1 ether;

        simps.createRoomAndBuyShares{value: price + protocolFee + subjectFee}(Simps.Curves.Quadratic, 1, steepness, floor, maxPrice, currentLimit);
        uint256 length = simps.getRoomsLength(address(simp1));
        assertEq(length, 1);

        vm.stopPrank();
    }

    function test_BuySellOneRoomLinear() public {
        vm.startPrank(simp1);
        uint256 room = simps.createRoom(Simps.Curves.Linear, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        // check balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 1);

        simps.sellShares(simp1, room, 1);

        // check balance
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();
    }

    function test_BuySellOneRoomQuadratic() public {
        vm.startPrank(simp1);
        uint256 room = simps.createRoom(Simps.Curves.Quadratic, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        // check balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 1);

        simps.sellShares(simp1, 0, 1);

        // check balance
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();
    }

    function test_BuySellOneRoomSigmoid() public {
        vm.startPrank(simp1);
        uint256 room = simps.createRoom(Simps.Curves.Sigmoid, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        // check balance
        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 1);

        simps.sellShares(simp1, room, 1);

        // check balance
        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();

    }

    function test_LoopBuySellSharesLinear() public {
        uint256 amount = 4;

        vm.startPrank(simp1);
        uint256 room = simps.createRoom(Simps.Curves.Linear, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);

        for (uint256 i = 0; i < amount; i++) {
            uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
            simps.buyShares{value: price}(simp1, room, 1);
        }

        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, amount);

        for (uint256 i = 0; i < amount; i++) {
            simps.sellShares(simp1, room, 1);
        }

        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        uint256 simpsEthBalance = address(simps).balance;
        assertEq(simpsEthBalance, 0);

        uint256 supply = simps.getSharesSupply(simp1, 0);
        assertEq(supply, 1);

        vm.stopPrank();
    }

    function test_Transfer() public {
        vm.startPrank(simp1);
        uint256 room = simps.createRoom(Simps.Curves.Linear, 16000, 1, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        uint256 price = simps.getBuyPriceAfterFee(simp1, room, 1);
        simps.buyShares{value: price}(simp1, room, 1);

        uint256 balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 1);

        simps.transfer(address(simp3), address(simp1), room, 1);

        balance = simps.getSharesBalance(simp1, room, simp2);
        assertEq(balance, 0);

        vm.stopPrank();

        vm.startPrank(simp3);
        balance = simps.getSharesBalance(simp1, room, simp3);
        assertEq(balance, 1);
        vm.stopPrank();
    }

    function test_SellRoomLinearBatchBuyLoopSell() public {
        uint256 amount = 100;

        vm.startPrank(simp1);
        uint256 room = simps.createRoom(Simps.Curves.Linear, 1200, 0, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);

        uint256 price = simps.getBuyPriceAfterFee(simp1, room, amount); 
        simps.buyShares{value: price}(simp1, room, amount);

        for (uint256 i = 0; i < amount; i++) {
            simps.sellShares(simp1, room, 1);
        }

        uint256 balance = simps.getSharesBalance(simp1, 0, simp2);
        assertEq(balance, 0);

        uint256 simpsEthBalance = address(simps).balance;
        assertEq(simpsEthBalance, 0);

        vm.stopPrank(); 
    }

    function test_SellRoomLinearLoopBuyBatchSell() public {
        uint256 amount = 30;

        vm.startPrank(simp1);
        uint256 room = simps.createRoom(Simps.Curves.Linear, 16000, 0, 0, 0);
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

    function test_SellRoomQuadraticBatchBuyLoopSell() public {
        uint256 amount = 20;

        vm.startPrank(simp1);
        uint256 room = simps.createRoom(Simps.Curves.Quadratic, 1200, 0, 0, 0);
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
        uint256 room = simps.createRoom(Simps.Curves.Quadratic, 16000, 0, 0, 0);
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
        uint256 room = simps.createRoom(Simps.Curves.Sigmoid, 1200, 0, 0, 0);
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

        uint256 room = simps.createRoom(Simps.Curves.Linear, 16000, 0, 0, 0);
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

        simps.createRoom(Simps.Curves.Linear, 16000, 0, 0, 0);
        vm.stopPrank();

        vm.startPrank(simp2);
        
        uint256 price = simps.getBuyPriceAfterFee(simp1, 0, amount); 
        simps.buyShares{value: price}(simp1, 0, amount);

        uint256 balance = simps.getSharesBalance(simp1, 0, simp2);
        assertEq(balance, amount);
        
        vm.stopPrank();   
    }

}