# FinalProject3

**SimpleSwap** is a minimal constant product AMM (Automated Market Maker) smart contract for two ERC20 tokens. It allows users to add/remove liquidity and perform token swaps without intermediaries, following the `x * y = k` invariant, inspired by Uniswap v1.

---

## Overview

This project was developed as part of the **Module 3 final assignment** in the **EthKipu Builders Solidity course**. It demonstrates core concepts of decentralized exchanges by implementing a simplified version of a liquidity pool from scratch—without relying on Uniswap libraries or external AMM logic.

---

## Features

- **Liquidity Provision**: Deposit two tokens in proportion and receive liquidity tokens.
- **Liquidity Removal**: Burn liquidity tokens to reclaim proportional shares of the reserves.
- **Token Swap**: Swap one token for the other based on constant product formula.
- **Reserve Tracking**: Keeps internal accounting of reserves for both tokens.
- **Initial Liquidity via Square Root Calculation**: Uses the Babylonian method for accurate initial LP token minting.

---

## Contract Architecture

solidity
constructor(address _tokenA, address _tokenB)
function addLiquidity(...) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)
function removeLiquidity(...) external returns (uint256 amountA, uint256 amountB)
function swap(...) external returns (uint256 amountOut)
function getReserves() external view returns (uint256, uint256)
function balanceOf(address user) external view returns (uint256)
function totalSupply() external view returns (uint256)


---

## Author

Leonel Cabral  
Smart Contract Builder  
EthKipu Training · Module 3 · 2025  
