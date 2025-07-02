// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title TokenA
/// @notice ERC20 token used as tokenA in the SimpleSwap contract
contract TokenA is ERC20 {
    constructor() ERC20("Token A", "USDT") {}

    /// @notice Allows you to mine tokens to an account
    /// @param to Receiving address
    /// @param amount Amount to be minted
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

