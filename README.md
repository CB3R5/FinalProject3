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

## Usage

### Deployment

This contract is designed for the Sepolia test network. You can deploy it using tools like **Hardhat**, **Foundry**, or **Remix**.

Example in Remix:
1. Load the contract and compile with Solidity ^0.8.20 or ^0.8.30
2. Deploy with a wallet connected to Sepolia (e.g., MetaMask)
3. Use the interface to add liquidity and perform swaps

---

## Module 3 Requirements

| Requirement                                      | Completed |
|--------------------------------------------------|-----------|
| Add/remove liquidity                            | ✔         |
| Exact swap between two tokens                   | ✔         |
| Use of SafeERC20                                | ✔         |
| Price functions (`getAmountOut`, `_getAmountIn`) | ✔         |
| Reentrancy protection                           | ✔         |
| Clean, readable, and modular code               | ✔         |
| Events for tracking                             | ✔         |

---

## Testing and Validation

You can test it in Remix or extend it with automated tests using Hardhat or Foundry.

Manual testing example in Remix:
1. Call `addLiquidity(...)` with two deployed ERC20 tokens
2. Execute `swapExactTokensForTokens(...)` ensuring `amountOutMin`
3. Verify reserves with `getReserves(...)`
4. Remove liquidity and verify balances

---

## References

- [Uniswap Whitepaper](https://uniswap.org/whitepaper-v2.pdf)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/4.x/)
- [Solidity Docs](https://docs.soliditylang.org)

---

## Author

Leonel Cabral  
Smart Contract Builder  
EthKipu Training · Module 3 · 2025  
