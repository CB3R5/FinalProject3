// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

contract TokenB is ERC20, Ownable {
    constructor() ERC20("TokenB", "TKB") Ownable(msg.sender) {
        uint256 initialSupply = 100_000_000_000 * 10 ** decimals();
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
