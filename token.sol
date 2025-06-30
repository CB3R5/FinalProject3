// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyTokens is ERC20 {
    constructor(string memory sym, string memory name)
        ERC20(name, sym)
    {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
