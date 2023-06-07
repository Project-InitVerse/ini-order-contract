# Order

We use OrderFactory.sol as the order contract for the chain user
## Test
You should do follow change in the contracts for test;
- Remove comments

  OrderFactory.sol:
  1. line 18
  2. line 60-62

   OrderBase.sol:
  1. line 54
  2. line 109-111
- Add comments

  OrderFactory.sol:.sol:
  1. line 16

  OrderBase.sol:
  1. line 52
  2. line 104
```
yarn hardhat test
```
## Compile
```
yarn hardhat compile
```
