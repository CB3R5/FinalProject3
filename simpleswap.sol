// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title SimpleSwap
/// @notice A minimal constant product AMM for a single token pair
contract SimpleSwap{
    /// @notice Token reserves for the liquidity pool
    struct Reserves {
        uint256 reserveA;
        uint256 reserveB;
    }

    Reserves private _reserves;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    ERC20 public tokenA;
    ERC20 public tokenB;

    /// @notice Emitted when liquidity is added
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Emitted when liquidity is removed
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Emitted when a swap occurs
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut);

    /// @notice Contract constructor
    /// @param _tokenA address of first ERC20 token
    /// @param _tokenB address of second ERC20 token
    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB, "Tokens must differ");
        require(_tokenA != address(0) && _tokenB != address(0), "Zero address");
        tokenA = ERC20(_tokenA);
        tokenB = ERC20(_tokenB);
    }

    /// @notice Returns current reserves
    function getReserves() external view returns (uint256, uint256) {
        return (_reserves.reserveA, _reserves.reserveB);
    }

    /// @notice Returns LP token balance of a user
    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    /// @notice Returns total LP supply
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

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

    /// @notice Add liquidity to the pool
    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(block.timestamp <= deadline, "Deadline passed");
        require(amountADesired > 0 && amountBDesired > 0, "Zero amount");

        uint256 rA = _reserves.reserveA;
        uint256 rB = _reserves.reserveB;

        if (rA == 0 && rB == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            uint256 optimalB = (amountADesired * rB) / rA;
            if (optimalB <= amountBDesired) {
                require(optimalB >= amountBMin, "Slippage B");
                amountA = amountADesired;
                amountB = optimalB;
            } else {
                uint256 optimalA = (amountBDesired * rA) / rB;
                require(optimalA >= amountAMin, "Slippage A");
                amountA = optimalA;
                amountB = amountBDesired;
            }
        }

        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Transfer A failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "Transfer B failed");

        liquidity = (_totalSupply == 0)
            ? _sqrt(amountA * amountB)
            : (amountA * _totalSupply) / rA;

        require(liquidity > 0, "Zero liquidity");

        _reserves.reserveA += amountA;
        _reserves.reserveB += amountB;
        _totalSupply += liquidity;
        _balances[to] += liquidity;

        emit LiquidityAdded(to, amountA, amountB, liquidity);
    }

    /// @notice Remove liquidity from the pool
    function removeLiquidity(
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(block.timestamp <= deadline, "Deadline passed");
        require(_balances[msg.sender] >= liquidity && liquidity > 0, "Invalid liquidity");

        uint256 rA = _reserves.reserveA;
        uint256 rB = _reserves.reserveB;

        amountA = (liquidity * rA) / _totalSupply;
        amountB = (liquidity * rB) / _totalSupply;

        require(amountA >= amountAMin, "Slippage A");
        require(amountB >= amountBMin, "Slippage B");

        _balances[msg.sender] -= liquidity;
        _totalSupply -= liquidity;
        _reserves.reserveA -= amountA;
        _reserves.reserveB -= amountB;

        require(tokenA.transfer(to, amountA), "Transfer A failed");
        require(tokenB.transfer(to, amountB), "Transfer B failed");

        emit LiquidityRemoved(to, amountA, amountB, liquidity);
    }

    /// @notice Swap between tokens
    function swap(
        uint256 amountIn,
        uint256 amountOutMin,
        bool swapAToB,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        require(block.timestamp <= deadline, "Deadline passed");
        require(amountIn > 0, "Zero input");

        uint256 rIn;
        uint256 rOut;

        if (swapAToB) {
            rIn = _reserves.reserveA;
            rOut = _reserves.reserveB;
        } else {
            rIn = _reserves.reserveB;
            rOut = _reserves.reserveA;
        }

        amountOut = (amountIn * rOut) / (rIn + amountIn);
        require(amountOut >= amountOutMin, "Slippage");

        if (swapAToB) {
            require(tokenA.transferFrom(msg.sender, address(this), amountIn), "Transfer A failed");
            require(tokenB.transfer(to, amountOut), "Transfer B failed");
            _reserves.reserveA += amountIn;
            _reserves.reserveB -= amountOut;
        } else {
            require(tokenB.transferFrom(msg.sender, address(this), amountIn), "Transfer B failed");
            require(tokenA.transfer(to, amountOut), "Transfer A failed");
            _reserves.reserveB += amountIn;
            _reserves.reserveA -= amountOut;
        }

        emit Swap(msg.sender, amountIn, amountOut);
    }
}
