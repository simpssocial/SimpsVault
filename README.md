# Simps

### Dependencies

```shell
$ forge install OpenZeppelin/openzeppelin-foundry-upgrades
$ forge install OpenZeppelin/openzeppelin-contracts-upgradeable
```

### Normal Operation
1. User wants to create a room that other users can buy and sell shares of
1. User calls the createRoom function that picks the bonding curve type (Original, Quadratic, Linear or Sigmoid). That function also takes 4 variables for the bonding curve parameters.
1. Another user calls getPrice() with the original share holders address and room number
1. The buyShares() funcion is called with the eth value the getPrice function returned
1. sellShares() is called at any time to receive the eth value back that the share is worth

### Other Features
1. transfer() function to send shares to another user
1. UUPS proxy
1. a createRoomAndBuyShares() function that lets you create a room and buy multiple tx's in one transaction


### Deploy To Anvil

```shell
$ forge create FixedMath --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY
$ forge script script/DeployVault.s.sol --broadcast --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --libraries src/FixedMath.sol:FixedMath:$FIXED_MATH
$ forge script script/DeployProxy.s.sol --broadcast --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY
```

