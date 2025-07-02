// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title TokenB
/// @notice ERC20 token used as tokenB in the SimpleSwap contract
contract TokenB is ERC20 {
    constructor() ERC20("Token B", "USDC") {}

    /// @notice Allows you to mine tokens to an account
    /// @param to Receiving address
    /// @param amount Amount to be minted
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

