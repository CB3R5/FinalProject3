// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title SimpleSwap - A basic token swap and liquidity pool implementation
/// @notice This contract allows users to swap between two tokens and provide liquidity
contract SimpleSwap is ERC20("SimpleSwap LP Token", "SSLP") {
    // The two tokens in the liquidity pool
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    // Current reserves of each token in the pool
    uint256 public reserveA;
    uint256 public reserveB;

    /// @notice Emitted when liquidity is added to the pool
    event LiquidityAdded(address indexed provider, uint amountA, uint amountB, uint liquidity);
    
    /// @notice Emitted when liquidity is removed from the pool
    event LiquidityRemoved(address indexed provider, uint amountA, uint amountB, uint liquidity);
    
    /// @notice Emitted when a swap occurs
    event Swap(address indexed user, uint amountIn, uint amountOut);

    /// @notice Initializes the contract with two tokens
    /// @param _tokenA Address of the first token
    /// @param _tokenB Address of the second token
    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB, "Tokens must differ");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /// @notice Internal function to calculate square root
    /// @dev Babylonian method for square root approximation
    /// @param y The number to calculate square root of
    /// @return z The square root result
    function _sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @notice Adds liquidity to the pool
    /// @dev Calculates optimal token amounts and mints LP tokens
    /// @param _tokenA Address of first token
    /// @param _tokenB Address of second token
    /// @param amountADesired Desired amount of token A
    /// @param amountBDesired Desired amount of token B
    /// @param amountAMin Minimum acceptable amount of token A
    /// @param amountBMin Minimum acceptable amount of token B
    /// @param to Address to receive LP tokens
    /// @param deadline Transaction must be completed before this timestamp
    /// @return amountA Actual amount of token A added
    /// @return amountB Actual amount of token B added
    /// @return liquidity Amount of LP tokens minted
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        require(block.timestamp <= deadline, "Deadline passed");
        require(_tokenA == address(tokenA) && _tokenB == address(tokenB), "Invalid token pair");

        if (reserveA == 0 && reserveB == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            uint optimalB = (amountADesired * reserveB) / reserveA;
            if (optimalB <= amountBDesired) {
                require(optimalB >= amountBMin, "Slippage B");
                amountA = amountADesired;
                amountB = optimalB;
            } else {
                uint optimalA = (amountBDesired * reserveA) / reserveB;
                require(optimalA >= amountAMin, "Slippage A");
                amountA = optimalA;
                amountB = amountBDesired;
            }
        }

        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Transfer A failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "Transfer B failed");

        liquidity = (totalSupply() == 0)
            ? _sqrt(amountA * amountB)
            : (amountA * totalSupply()) / reserveA;

        _mint(to, liquidity);
        reserveA += amountA;
        reserveB += amountB;
        emit LiquidityAdded(to, amountA, amountB, liquidity);
    }

    /// @notice Removes liquidity from the pool
    /// @dev Burns LP tokens and returns proportional amounts of both tokens
    /// @param _tokenA Address of first token
    /// @param _tokenB Address of second token
    /// @param liquidity Amount of LP tokens to burn
    /// @param amountAMin Minimum acceptable amount of token A
    /// @param amountBMin Minimum acceptable amount of token B
    /// @param to Address to receive underlying tokens
    /// @param deadline Transaction must be completed before this timestamp
    /// @return amountA Actual amount of token A received
    /// @return amountB Actual amount of token B received
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB) {
        require(block.timestamp <= deadline, "Deadline passed");
        require(_tokenA == address(tokenA) && _tokenB == address(tokenB), "Invalid token pair");

        uint total = totalSupply();
        amountA = (liquidity * reserveA) / total;
        amountB = (liquidity * reserveB) / total;

        require(amountA >= amountAMin, "Slippage A");
        require(amountB >= amountBMin, "Slippage B");

        _burn(msg.sender, liquidity);
        reserveA -= amountA;
        reserveB -= amountB;

        require(tokenA.transfer(to, amountA), "Transfer A failed");
        require(tokenB.transfer(to, amountB), "Transfer B failed");

        emit LiquidityRemoved(to, amountA, amountB, liquidity);
    }

    /// @notice Swaps exact tokens for tokens
    /// @dev Performs token swap using constant product formula
    /// @param amountIn Amount of input tokens to swap
    /// @param amountOutMin Minimum acceptable amount of output tokens
    /// @param path Array with two token addresses [input, output]
    /// @param to Address to receive output tokens
    /// @param deadline Transaction must be completed before this timestamp
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        require(block.timestamp <= deadline, "Deadline passed");
        require(path.length == 2, "Path length must be 2");
        require(path[0] == address(tokenA) || path[0] == address(tokenB), "Invalid token A");
        require(path[1] == address(tokenA) || path[1] == address(tokenB), "Invalid token B");

        (IERC20 input, IERC20 output, uint reserveIn, uint reserveOut) =
            path[0] == address(tokenA)
            ? (tokenA, tokenB, reserveA, reserveB)
            : (tokenB, tokenA, reserveB, reserveA);

        require(input.transferFrom(msg.sender, address(this), amountIn), "Transfer in failed");
        uint amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "Slippage");
        require(output.transfer(to, amountOut), "Transfer out failed");

        if (address(input) == address(tokenA)) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        emit Swap(msg.sender, amountIn, amountOut);
    }

    /// @notice Gets the current price ratio between tokens
    /// @param _tokenA Address of first token
    /// @param _tokenB Address of second token
    /// @return price Price ratio scaled by 1e18
    function getPrice(address _tokenA, address _tokenB) external view returns (uint price) {
        require((_tokenA == address(tokenA) && _tokenB == address(tokenB)) ||
                (_tokenA == address(tokenB) && _tokenB == address(tokenA)), "Invalid tokens");
        price = (_tokenA == address(tokenA))
            ? (reserveB * 1e18) / reserveA
            : (reserveA * 1e18) / reserveB;
    }

    /// @notice Calculates output amount for given input
    /// @dev Uses constant product formula (x*y=k)
    /// @param amountIn Amount of input tokens
    /// @param reserveIn Reserve amount of input token
    /// @param reserveOut Reserve amount of output token
    /// @return amountOut Calculated output amount
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, "Zero input");
        require(reserveIn > 0 && reserveOut > 0, "Zero reserves");
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    }
}
