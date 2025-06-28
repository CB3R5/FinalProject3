// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SimpleSwap - Decentralized Exchange Contract
/// @notice Minimal DEX implementation with liquidity provision and token swap functionality
/// @dev Inspired by Uniswap v1 with simplified features
contract SimpleSwap is ReentrancyGuard {
    using SafeERC20 for IERC20; // Safe ERC20 operations

    // Constants for fee calculation (0.3% fee)
    uint256 private constant FEE_NUMERATOR = 997;   // 99.7% (100% - 0.3%)
    uint256 private constant FEE_DENOMINATOR = 1000; // 100% basis

    /// @notice Structure to store reserve amounts for a token pair
    struct Reserves {
        uint256 reserve0; // Reserve amount for token0
        uint256 reserve1; // Reserve amount for token1
    }

    /// @notice Structure representing a liquidity pool pair
    struct Pair {
        Reserves reserves;           // Current reserves
        uint256 totalSupply;         // Total LP tokens minted
        mapping(address => uint256) balances; // LP token balances per user
    }

    // Mapping of token pairs to their liquidity pools
    mapping(address => mapping(address => Pair)) private _pairs;

    // Events
    event LiquidityAdded(
        address indexed token0,
        address indexed token1,
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );
    event LiquidityRemoved(
        address indexed token0,
        address indexed token1,
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );
    event TokensSwapped(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed user,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice Get user's LP token balance for a pair
    /// @param tokenA First token in pair
    /// @param tokenB Second token in pair
    /// @param user Address to check balance for
    /// @return LP token balance of the user
    function balanceOf(address tokenA, address tokenB, address user) external view returns (uint256) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        return _pairs[token0][token1].balances[user];
    }

    /// @notice Get current reserves for a token pair
    /// @param tokenA First token in pair
    /// @param tokenB Second token in pair
    /// @return reserveA Reserve amount of tokenA
    /// @return reserveB Reserve amount of tokenB
    function getReserves(address tokenA, address tokenB) external view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        Reserves memory r = _pairs[token0][token1].reserves;
        // Return reserves in original token order
        (reserveA, reserveB) = tokenA == token0 ? (r.reserve0, r.reserve1) : (r.reserve1, r.reserve0);
    }

    /// @notice Calculate output amount for a given input
    /// @param amountIn Input token amount
    /// @param tokenIn Input token address
    /// @param tokenOut Output token address
    /// @return Output token amount
    function getAmountOut(uint256 amountIn, address tokenIn, address tokenOut) external view returns (uint256) {
        (address token0, address token1) = _sortTokens(tokenIn, tokenOut);
        Pair storage pair = _pairs[token0][token1];
        (uint256 reserveIn, uint256 reserveOut) = tokenIn == token0 ?
            (pair.reserves.reserve0, pair.reserves.reserve1) :
            (pair.reserves.reserve1, pair.reserves.reserve0);
        return _getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /// @dev Sort token addresses to ensure consistent pair ordering
    /// @param tokenA First token address
    /// @param tokenB Second token address
    /// @return token0 First sorted token
    /// @return token1 Second sorted token
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        require(tokenA != tokenB, "Identical tokens");
        require(tokenA != address(0) && tokenB != address(0), "Zero address");
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /// @dev Calculate output amount given input amount and reserves
    /// @param amountIn Input amount
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @return amountOut Calculated output amount
    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        require(amountIn > 0 && reserveIn > 0 && reserveOut > 0, "Invalid input");
        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;
        return (amountInWithFee * reserveOut) / (reserveIn * FEE_DENOMINATOR + amountInWithFee);
    }

    /// @dev Calculate required input amount for desired output
    /// @param amountOut Desired output amount
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @return amountIn Required input amount
    function _getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        require(amountOut > 0 && reserveIn > 0 && reserveOut > amountOut, "Invalid output");
        uint256 numerator = reserveIn * amountOut * FEE_DENOMINATOR;
        uint256 denominator = (reserveOut - amountOut) * FEE_NUMERATOR;
        return (numerator / denominator) + 1; // Round up
    }

    /// @dev Returns the smaller of two numbers
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Babylonian square root implementation
    /// @param y Number to calculate square root of
    /// @return z Square root result
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = (y >> 1) + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) >> 1;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @notice Add liquidity to a pool
    /// @param tokenA First token in pair
    /// @param tokenB Second token in pair
    /// @param amountADesired Desired amount of tokenA to add
    /// @param amountBDesired Desired amount of tokenB to add
    /// @param amountAMin Minimum acceptable amount of tokenA
    /// @param amountBMin Minimum acceptable amount of tokenB
    /// @param to Address to receive LP tokens
    /// @param deadline Transaction expiry timestamp
    /// @return amountA Actual amount of tokenA added
    /// @return amountB Actual amount of tokenB added
    /// @return liquidity Amount of LP tokens minted
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(block.timestamp <= deadline, "Expired");
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        Pair storage pair = _pairs[token0][token1];

        (uint256 reserve0, uint256 reserve1) = (pair.reserves.reserve0, pair.reserves.reserve1);

        // Initial liquidity provision
        if (reserve0 == 0 && reserve1 == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // Calculate optimal amounts based on current ratio
            uint256 amountBOptimal = (amountADesired * reserve1) / reserve0;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Slippage B");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * reserve0) / reserve1;
                require(amountAOptimal >= amountAMin, "Slippage A");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }

        // Transfer tokens from user
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);

        // Calculate liquidity to mint
        if (pair.totalSupply == 0) {
            // Initial liquidity uses geometric mean
            liquidity = _sqrt(amountA * amountB);
        } else {
            // Subsequent liquidity proportional to existing reserves
            liquidity = _min(
                (amountA * pair.totalSupply) / reserve0,
                (amountB * pair.totalSupply) / reserve1
            );
        }

        require(liquidity > 0, "Liquidity zero");

        // Update reserves and balances
        pair.reserves.reserve0 = reserve0 + amountA;
        pair.reserves.reserve1 = reserve1 + amountB;
        pair.totalSupply += liquidity;
        pair.balances[to] += liquidity;

        emit LiquidityAdded(token0, token1, to, amountA, amountB, liquidity);
    }

    /// @notice Remove liquidity from a pool
    /// @param tokenA First token in pair
    /// @param tokenB Second token in pair
    /// @param liquidity Amount of LP tokens to burn
    /// @param amountAMin Minimum acceptable amount of tokenA
    /// @param amountBMin Minimum acceptable amount of tokenB
    /// @param to Address to receive underlying tokens
    /// @param deadline Transaction expiry timestamp
    /// @return amountA Amount of tokenA received
    /// @return amountB Amount of tokenB received
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        require(block.timestamp <= deadline, "Expired");
        require(liquidity > 0, "Zero liquidity");

        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        Pair storage pair = _pairs[token0][token1];
        require(pair.balances[msg.sender] >= liquidity, "Insufficient LP");

        uint256 reserve0 = pair.reserves.reserve0;
        uint256 reserve1 = pair.reserves.reserve1;
        uint256 totalSupply = pair.totalSupply;

        // Calculate proportional share of reserves
        amountA = (liquidity * reserve0) / totalSupply;
        amountB = (liquidity * reserve1) / totalSupply;

        require(amountA >= amountAMin, "Min A");
        require(amountB >= amountBMin, "Min B");

        // Update reserves and balances
        pair.reserves.reserve0 = reserve0 - amountA;
        pair.reserves.reserve1 = reserve1 - amountB;
        pair.totalSupply -= liquidity;
        pair.balances[msg.sender] -= liquidity;

        // Transfer tokens to user
        IERC20(tokenA).safeTransfer(to, amountA);
        IERC20(tokenB).safeTransfer(to, amountB);

        emit LiquidityRemoved(token0, token1, msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Execute a token swap
    /// @param amountIn Exact input amount
    /// @param amountOutMin Minimum acceptable output amount
    /// @param path Array with 2 elements: [inputToken, outputToken]
    /// @param to Address to receive output tokens
    /// @param deadline Transaction expiry timestamp
    /// @return amounts Array with input and output amounts
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256[] memory amounts) {
        require(block.timestamp <= deadline, "Expired");
        require(path.length == 2, "Path must be 2");
        require(amountIn > 0, "Zero input");

        address tokenIn = path[0];
        address tokenOut = path[1];

        (address token0, address token1) = _sortTokens(tokenIn, tokenOut);
        Pair storage pair = _pairs[token0][token1];

        (uint256 reserveIn, uint256 reserveOut) = tokenIn == token0 ?
            (pair.reserves.reserve0, pair.reserves.reserve1) :
            (pair.reserves.reserve1, pair.reserves.reserve0);

        // Transfer input tokens from user
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Calculate output amount with fee
        uint256 amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "Insufficient output");

        // Update reserves
        if (tokenIn == token0) {
            pair.reserves.reserve0 = reserveIn + amountIn;
            pair.reserves.reserve1 = reserveOut - amountOut;
        } else {
            pair.reserves.reserve1 = reserveIn + amountIn;
            pair.reserves.reserve0 = reserveOut - amountOut;
        }

        // Transfer output tokens to user
        IERC20(tokenOut).safeTransfer(to, amountOut);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit TokensSwapped(tokenIn, tokenOut, msg.sender, amountIn, amountOut);
    }
}