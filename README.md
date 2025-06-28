# FinalProject3

A smart contract inspired by Uniswap that allows adding/removing liquidity and swapping ERC20 tokens without relying on any external protocol.

> Final project for Module 3 - Builder Training at EthKipu

## Features

- Add and remove liquidity with proportional calculations
- Token swaps with 0.3% fee (Uniswap style)
- Automatic reserve maintenance
- Price calculations (`getAmountOut`, `_getAmountIn`)
- Reentrancy protection (`ReentrancyGuard`)
- Secure token handling with `SafeERC20`
- Events for on-chain traceability

---

## Functionalities

### `addLiquidity(...)`
Allows a provider to add tokens to a pair and receive liquidity tokens representing their share.

### `removeLiquidity(...)`
Allows withdrawing liquidity and receiving the underlying tokens in proportion to the pool.

### `swapExactTokensForTokens(...)`
Executes a swap between two compatible tokens, applying a 0.3% fee and ensuring a minimum output (`slippage control`).

### `getReserves(...)`
Returns the current reserves of the token pair.

### `balanceOf(...)`
Shows a user's liquidity token balance for a specific pair.

---

## Author

Leonel Cabral  
Smart Contract Builder  
EthKipu Training · Module 3 · 2025  
