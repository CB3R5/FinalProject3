# FinalProject3

**SimpleSwap** This project implements a simplified Automated Market Maker (AMM) similar to Uniswap, allowing users to add/remove liquidity and swap tokens.

---

## Contracts Overview

This project was developed as part of the **Module 3 final assignment** in the **EthKipu Builders Solidity course**. It demonstrates core concepts of decentralized exchanges by implementing a simplified version of a liquidity pool from scratch—without relying on Uniswap libraries or external AMM logic.

### 1. TokenA.sol / TokenB.sol

Standard ERC-20 tokens with a public `mint` function for testing and liquidity provision.

### 2. SimpleSwap.sol

Core AMM contract implementing:

* `addLiquidity`: Allows users to provide liquidity for a token pair.
* `removeLiquidity`: Withdraw liquidity and receive tokens.
* `swapExactTokensForTokens`: Token swap based on constant product formula.
* `getPrice`: Returns the price of one token in terms of the other.
* `getAmountOut`: Calculates how many tokens will be received in a swap.

---

## Deployment Steps

1. **Deploy TokenA**

   * Name: `TokenA`
   * Symbol: `USDT`

2. **Deploy TokenB**

   * Name: `TokenB`
   * Symbol: `USDC`

3. **Deploy SimpleSwap**

   * Constructor arguments: `address of TokenA`, `address of TokenB`

### Mint tokens to the SwapVerifier contract

The `verify()` function expects that the `SwapVerifier` contract already holds enough tokenA and tokenB to perform the tests.

Mint tokenA and tokenB from your wallet to `SwapVerifier`:

Use the `mint(address to, uint256 amount)` function on both token contracts.

Parameters:

* `to`: `0x9f8F02DAB384DDdf1591C3366069Da3Fb0018220` (SwapVerifier address)
* `amount`: `1000000000000000000000` (1000 tokens, assuming 18 decimals)

Ensure that both tokens are successfully minted and that `balanceOf(SwapVerifier)` returns enough balance.

### Approve TokenA

Go to the Write Contract tab of TokenA

Function: `approve`

Parameters:

* `spender`: `0x39Ab6BCC04e85182fd1323b306F9F7900EC5Be10` (SimpleSwap address)
* `amount`: `1000000000000000000000` (1000 tokens)

Repeat the same process for TokenB

### Execute `addLiquidity` on SimpleSwap

Go to SimpleSwap → Write Contract tab → connect your wallet

Function: `addLiquidity`

Parameters:

| Field          | Value                                               |
| -------------- | --------------------------------------------------- |
| tokenA         | 0xDd79601DF7D1c17F783736d6fE6a87B7D170b0D7          |
| tokenB         | 0xEA59ca4773DfC00B02B4d49AF911906550057ead          |
| amountADesired | 100000000000000000000 (100 TokenA)                  |
| amountBDesired | 100000000000000000000 (100 TokenB)                  |
| amountAMin     | 100000000000000000000 (0 slippage)                  |
| amountBMin     | 100000000000000000000 (0 slippage)                  |
| to             | 0x790FD2ECf5eDAb4FCb651A0dCa41f2E4dc673ccC (wallet) |
| deadline       | 9999999999 (far future timestamp)                   |

### Call the `verify()` function

Go to the Write Contract section of the `SwapVerifier` contract and connect with your wallet.

Use the following parameters:

```solidity
verify(
  swapContract = 0x39Ab6BCC04e85182fd1323b306F9F7900EC5Be10,
  tokenA = 0xDd79601DF7D1c17F783736d6fE6a87B7D170b0D7,
  tokenB = 0xEA59ca4773DfC00B02B4d49AF911906550057ead,
  amountA = 100000000000000000000,       // 100 tokenA
  amountB = 100000000000000000000,       // 100 tokenB
  amountIn = 10000000000000000000,       // 10 tokenA for swap
  author = "CABRAL Leonel"               // Your name as string
)
```

If everything is correct, the `verify()` function will execute successfully and log your author name.

---

### Address

* TokenA: `0xDd79601DF7D1c17F783736d6fE6a87B7D170b0D7`
* TokenB: `0xEA59ca4773DfC00B02B4d49AF911906550057ead`
* SimpleSwap: `0x39Ab6BCC04e85182fd1323b306F9F7900EC5Be10`
* SwapVerifier: `0x9f8f02dab384dddf1591c3366069da3fb0018220`

### Sepolia Etherscan Links

* tokena.sol: [https://sepolia.etherscan.io/address/0xdd79601df7d1c17f783736d6fe6a87b7d170b0d7#code](https://sepolia.etherscan.io/address/0xdd79601df7d1c17f783736d6fe6a87b7d170b0d7#code)
* tokenb.sol: [https://sepolia.etherscan.io/address/0xea59ca4773dfc00b02b4d49af911906550057ead#code](https://sepolia.etherscan.io/address/0xea59ca4773dfc00b02b4d49af911906550057ead#code)
* simpleswap.sol: [https://sepolia.etherscan.io/address/0x39ab6bcc04e85182fd1323b306f9f7900ec5be10#code](https://sepolia.etherscan.io/address/0x39ab6bcc04e85182fd1323b306f9f7900ec5be10#code)
* swapverifier.sol: [https://sepolia.etherscan.io/address/0x9f8f02dab384dddf1591c3366069da3fb0018220#code](https://sepolia.etherscan.io/address/0x9f8f02dab384dddf1591c3366069da3fb0018220#code)

### Transaction Details

* Call `verify`: [https://sepolia.etherscan.io/tx/0xeda6030048f98c847d3e7d453068c42bc02bcd0b1bc05bde231f3c1774e81df5](https://sepolia.etherscan.io/tx/0xeda6030048f98c847d3e7d453068c42bc02bcd0b1bc05bde231f3c1774e81df5)

## Author

Leonel Cabral
Smart Contract Builder
EthKipu Training · Module 3 · 2025
