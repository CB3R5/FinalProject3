// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SimpleSwap - Minimal DEX for Single Token Pair
contract SimpleSwap is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Structs ---
    struct Reserves {
        uint256 reserveA;
        uint256 reserveB;
    }

    Reserves private _reserves;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    IERC20 public tokenA;
    IERC20 public tokenB;

    // --- Events ---
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB && _tokenA != address(0) && _tokenB != address(0));
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    // --- Views ---
    function getReserves() external view returns (uint256, uint256) {
        return (_reserves.reserveA, _reserves.reserveB);
    }

    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // --- Internal ---
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // --- Core Functions ---
    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(block.timestamp <= deadline);
        require(amountADesired > 0 && amountBDesired > 0);

        uint256 rA = _reserves.reserveA;
        uint256 rB = _reserves.reserveB;

        if (rA == 0 && rB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 optimalB = (amountADesired * rB) / rA;
            if (optimalB <= amountBDesired) {
                require(optimalB >= amountBMin);
                (amountA, amountB) = (amountADesired, optimalB);
            } else {
                uint256 optimalA = (amountBDesired * rA) / rB;
                require(optimalA >= amountAMin);
                (amountA, amountB) = (optimalA, amountBDesired);
            }
        }

        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenB.safeTransferFrom(msg.sender, address(this), amountB);

        if (_totalSupply == 0) {
            liquidity = _sqrt(amountA * amountB);
        } else {
            liquidity = (amountA * _totalSupply) / rA;
        }

        require(liquidity > 0);

        _reserves.reserveA = rA + amountA;
        _reserves.reserveB = rB + amountB;
        _totalSupply += liquidity;
        _balances[to] += liquidity;

        emit LiquidityAdded(to, amountA, amountB, liquidity);
    }

    function removeLiquidity(
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        require(block.timestamp <= deadline);
        require(liquidity > 0 && _balances[msg.sender] >= liquidity);

        uint256 rA = _reserves.reserveA;
        uint256 rB = _reserves.reserveB;

        amountA = (liquidity * rA) / _totalSupply;
        amountB = (liquidity * rB) / _totalSupply;

        require(amountA >= amountAMin);
        require(amountB >= amountBMin);

        _reserves.reserveA = rA - amountA;
        _reserves.reserveB = rB - amountB;
        _totalSupply -= liquidity;
        _balances[msg.sender] -= liquidity;

        tokenA.safeTransfer(to, amountA);
        tokenB.safeTransfer(to, amountB);

        emit LiquidityRemoved(to, amountA, amountB, liquidity);
    }

    function swap(uint256 amountIn, uint256 amountOutMin, bool swapAToB, address to, uint256 deadline) external nonReentrant returns (uint256 amountOut) {
        require(block.timestamp <= deadline);
        require(amountIn > 0);

        (uint256 rIn, uint256 rOut) = swapAToB
            ? (_reserves.reserveA, _reserves.reserveB)
            : (_reserves.reserveB, _reserves.reserveA);

        require(rIn > 0 && rOut > 0);

        uint256 amountInWithFee = amountIn;
        amountOut = (amountInWithFee * rOut) / (rIn + amountInWithFee);

        require(amountOut >= amountOutMin);

        if (swapAToB) {
            tokenA.safeTransferFrom(msg.sender, address(this), amountIn);
            tokenB.safeTransfer(to, amountOut);
            _reserves.reserveA += amountIn;
            _reserves.reserveB -= amountOut;
        } else {
            tokenB.safeTransferFrom(msg.sender, address(this), amountIn);
            tokenA.safeTransfer(to, amountOut);
            _reserves.reserveB += amountIn;
            _reserves.reserveA -= amountOut;
        }

        emit Swap(msg.sender, amountIn, amountOut);
    }
}
