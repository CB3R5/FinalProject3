// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title SimpleSwap - Minimal constant product AMM for two ERC20 tokens
contract SimpleSwap {
    /// @notice Reserves for each token
    struct Reserves {
        uint256 reserveA;
        uint256 reserveB;
    }

    /// @notice Token A and B addresses
    ERC20 public tokenA;
    ERC20 public tokenB;

    /// @notice Current reserves
    Reserves private _reserves;

    /// @notice Total liquidity tokens minted
    uint256 private _totalSupply;

    /// @notice Liquidity balances per user
    mapping(address => uint256) private _balances;

    /// @notice Emitted when liquidity is added
    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Emitted when liquidity is removed
    event LiquidityRemoved(address indexed user, uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Emitted on token swap
    event Swapped(address indexed user, uint256 amountIn, uint256 amountOut);

    /// @notice Initializes the AMM with a token pair
    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB && _tokenA != address(0) && _tokenB != address(0));
        tokenA = ERC20(_tokenA);
        tokenB = ERC20(_tokenB);
    }

    /// @notice Returns current reserves
    function getReserves() external view returns (uint256, uint256) {
        return (_reserves.reserveA, _reserves.reserveB);
    }

    /// @notice Returns liquidity balance of a user
    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    /// @notice Returns total liquidity supply
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Add liquidity to the pool
    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(block.timestamp <= deadline);
        require(amountADesired > 0 && amountBDesired > 0);

        uint256 rA = _reserves.reserveA;
        uint256 rB = _reserves.reserveB;

        if (rA == 0 && rB == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            uint256 optimalB = (amountADesired * rB) / rA;
            if (optimalB <= amountBDesired) {
                require(optimalB >= amountBMin);
                amountA = amountADesired;
                amountB = optimalB;
            } else {
                uint256 optimalA = (amountBDesired * rA) / rB;
                require(optimalA >= amountAMin);
                amountA = optimalA;
                amountB = amountBDesired;
            }
        }

        // Interactions
        require(tokenA.transferFrom(msg.sender, address(this), amountA));
        require(tokenB.transferFrom(msg.sender, address(this), amountB));

        if (_totalSupply == 0) {
            liquidity = _sqrt(amountA * amountB);
        } else {
            liquidity = (amountA * _totalSupply) / rA;
        }

        require(liquidity > 0);

        // Effects
        _reserves.reserveA = rA + amountA;
        _reserves.reserveB = rB + amountB;
        _totalSupply += liquidity;
        _balances[to] += liquidity;

        emit LiquidityAdded(to, amountA, amountB, liquidity);
    }

    /// @notice Remove liquidity and get tokens back
    function removeLiquidity(
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(block.timestamp <= deadline);
        require(_balances[msg.sender] >= liquidity && liquidity > 0);

        uint256 rA = _reserves.reserveA;
        uint256 rB = _reserves.reserveB;

        amountA = (liquidity * rA) / _totalSupply;
        amountB = (liquidity * rB) / _totalSupply;

        require(amountA >= amountAMin);
        require(amountB >= amountBMin);

        // Effects
        _reserves.reserveA = rA - amountA;
        _reserves.reserveB = rB - amountB;
        _totalSupply -= liquidity;
        _balances[msg.sender] -= liquidity;

        // Interactions
        require(tokenA.transfer(to, amountA));
        require(tokenB.transfer(to, amountB));

        emit LiquidityRemoved(to, amountA, amountB, liquidity);
    }

    /// @notice Swap token A for B or viceversa
    function swap(
        uint256 amountIn,
        uint256 amountOutMin,
        bool swapAToB,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        require(block.timestamp <= deadline);
        require(amountIn > 0);

        uint256 rIn = swapAToB ? _reserves.reserveA : _reserves.reserveB;
        uint256 rOut = swapAToB ? _reserves.reserveB : _reserves.reserveA;

        amountOut = (amountIn * rOut) / (rIn + amountIn);
        require(amountOut >= amountOutMin);

        // Interactions
        if (swapAToB) {
            require(tokenA.transferFrom(msg.sender, address(this), amountIn));
            require(tokenB.transfer(to, amountOut));
            _reserves.reserveA += amountIn;
            _reserves.reserveB -= amountOut;
        } else {
            require(tokenB.transferFrom(msg.sender, address(this), amountIn));
            require(tokenA.transfer(to, amountOut));
            _reserves.reserveB += amountIn;
            _reserves.reserveA -= amountOut;
        }

        emit Swapped(msg.sender, amountIn, amountOut);
    }

    /// @notice Internal sqrt helper using Babylonian method
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
}
