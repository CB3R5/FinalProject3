// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SimpleSwap - Decentralized Exchange Contract
/// @notice Minimal DEX with liquidity provision and token swap
contract SimpleSwap is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant FEE_NUMERATOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;

    struct Reserves {
        uint256 reserve0;
        uint256 reserve1;
    }

    struct Pair {
        Reserves reserves;
        uint256 totalSupply;
        mapping(address => uint256) balances;
    }

    mapping(address => mapping(address => Pair)) private _pairs;

    event LiquidityAdded(address indexed token0, address indexed token1, address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity);
    event LiquidityRemoved(address indexed token0, address indexed token1, address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity);
    event TokensSwapped(address indexed tokenIn, address indexed tokenOut, address indexed user, uint256 amountIn, uint256 amountOut);

    function balanceOf(address tokenA, address tokenB, address user) external view returns (uint256) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        return _pairs[token0][token1].balances[user];
    }

    function getReserves(address tokenA, address tokenB) external view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        Reserves memory r = _pairs[token0][token1].reserves;
        (reserveA, reserveB) = tokenA == token0 ? (r.reserve0, r.reserve1) : (r.reserve1, r.reserve0);
    }

    function getAmountOut(uint256 amountIn, address tokenIn, address tokenOut) external view returns (uint256) {
        (address token0, address token1) = _sortTokens(tokenIn, tokenOut);
        Pair storage pair = _pairs[token0][token1];
        (uint256 reserveIn, uint256 reserveOut) = tokenIn == token0 ?
            (pair.reserves.reserve0, pair.reserves.reserve1) :
            (pair.reserves.reserve1, pair.reserves.reserve0);
        return _getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function _sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        require(tokenA != tokenB, "Identical tokens");
        require(tokenA != address(0) && tokenB != address(0), "Zero address");
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        require(amountIn > 0 && reserveIn > 0 && reserveOut > 0, "Invalid input");
        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;
        return (amountInWithFee * reserveOut) / (reserveIn * FEE_DENOMINATOR + amountInWithFee);
    }

    function _getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        require(amountOut > 0 && reserveIn > 0 && reserveOut > amountOut, "Invalid output");
        uint256 numerator = reserveIn * amountOut * FEE_DENOMINATOR;
        uint256 denominator = (reserveOut - amountOut) * FEE_NUMERATOR;
        return (numerator / denominator) + 1;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

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

        if (reserve0 == 0 && reserve1 == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
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

        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);

        if (pair.totalSupply == 0) {
            liquidity = _sqrt(amountA * amountB);
        } else {
            liquidity = _min((amountA * pair.totalSupply) / reserve0, (amountB * pair.totalSupply) / reserve1);
        }

        require(liquidity > 0, "Liquidity zero");

        pair.reserves.reserve0 = reserve0 + amountA;
        pair.reserves.reserve1 = reserve1 + amountB;
        pair.totalSupply += liquidity;
        pair.balances[to] += liquidity;

        emit LiquidityAdded(token0, token1, to, amountA, amountB, liquidity);
    }

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

        amountA = (liquidity * reserve0) / totalSupply;
        amountB = (liquidity * reserve1) / totalSupply;

        require(amountA >= amountAMin, "Min A");
        require(amountB >= amountBMin, "Min B");

        pair.reserves.reserve0 = reserve0 - amountA;
        pair.reserves.reserve1 = reserve1 - amountB;
        pair.totalSupply -= liquidity;
        pair.balances[msg.sender] -= liquidity;

        IERC20(tokenA).safeTransfer(to, amountA);
        IERC20(tokenB).safeTransfer(to, amountB);

        emit LiquidityRemoved(token0, token1, msg.sender, amountA, amountB, liquidity);
    }

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

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "Insufficient output");

        if (tokenIn == token0) {
            pair.reserves.reserve0 = reserveIn + amountIn;
            pair.reserves.reserve1 = reserveOut - amountOut;
        } else {
            pair.reserves.reserve1 = reserveIn + amountIn;
            pair.reserves.reserve0 = reserveOut - amountOut;
        }

        IERC20(tokenOut).safeTransfer(to, amountOut);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit TokensSwapped(tokenIn, tokenOut, msg.sender, amountIn, amountOut);
    }
}
