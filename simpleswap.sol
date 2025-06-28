// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SimpleSwap is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant FEE_NUMERATOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;

    struct Reserves {
        uint128 reserve0;
        uint128 reserve1;
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

    function getReserves(address tokenA, address tokenB) public view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        Reserves memory r = _pairs[token0][token1].reserves;
        (reserveA, reserveB) = tokenA == token0 ? (r.reserve0, r.reserve1) : (r.reserve1, r.reserve0);
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
        require(block.timestamp <= deadline, "exp");

        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        Pair storage pair = _pairs[token0][token1];
        Reserves memory r = pair.reserves;

        if (r.reserve0 == 0 && r.reserve1 == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = (amountADesired * r.reserve1) / r.reserve0;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "slipB");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * r.reserve0) / r.reserve1;
                require(amountAOptimal >= amountAMin, "slipA");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }

        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);

        liquidity = pair.totalSupply == 0 ? _sqrt(amountA * amountB)
            : _min((amountA * pair.totalSupply) / r.reserve0, (amountB * pair.totalSupply) / r.reserve1);

        require(liquidity > 0, "liq0");

        pair.reserves = Reserves(
            uint128(r.reserve0 + amountA),
            uint128(r.reserve1 + amountB)
        );
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
        require(block.timestamp <= deadline && liquidity > 0, "inv");

        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        Pair storage pair = _pairs[token0][token1];
        require(pair.balances[msg.sender] >= liquidity, "bal");

        Reserves memory r = pair.reserves;
        uint256 supply = pair.totalSupply;

        amountA = (liquidity * r.reserve0) / supply;
        amountB = (liquidity * r.reserve1) / supply;

        require(amountA >= amountAMin && amountB >= amountBMin, "slip");

        pair.reserves = Reserves(
            uint128(r.reserve0 - amountA),
            uint128(r.reserve1 - amountB)
        );
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
        require(block.timestamp <= deadline && path.length == 2 && amountIn > 0, "inv");

        address tokenIn = path[0];
        address tokenOut = path[1];

        (address token0, address token1) = _sortTokens(tokenIn, tokenOut);
        Pair storage pair = _pairs[token0][token1];

        (uint256 rIn, uint256 rOut) = tokenIn == token0 ? (pair.reserves.reserve0, pair.reserves.reserve1)
                                                        : (pair.reserves.reserve1, pair.reserves.reserve0);

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        uint256 amountOut = _getAmountOut(amountIn, rIn, rOut);
        require(amountOut >= amountOutMin, "slip");

        if (tokenIn == token0) {
            pair.reserves = Reserves(
                uint128(rIn + amountIn),
                uint128(rOut - amountOut)
            );
        } else {
            pair.reserves = Reserves(
                uint128(rOut - amountOut),
                uint128(rIn + amountIn)
            );
        }

        IERC20(tokenOut).safeTransfer(to, amountOut);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit TokensSwapped(tokenIn, tokenOut, msg.sender, amountIn, amountOut);
    }

    function _sortTokens(address a, address b) internal pure returns (address, address) {
        require(a != b && a != address(0) && b != address(0), "inv");
        return a < b ? (a, b) : (b, a);
    }

    function _getAmountOut(uint256 amtIn, uint256 resIn, uint256 resOut) internal pure returns (uint256) {
        uint256 amtInWFee = amtIn * FEE_NUMERATOR;
        return (amtInWFee * resOut) / (resIn * FEE_DENOMINATOR + amtInWFee);
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = (y / 2) + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}