// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts@5.1.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.1.0/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor(
        address initialOwner,
        string memory tokenName,
        string memory tokenSymbol
    ) ERC20(tokenName, tokenSymbol) Ownable(initialOwner) {}

    function mint(address to, uint256 amount) public onlyOwner {
        uint256 mintedAmount = amount * 10**decimals();
        _mint(to, mintedAmount);
    }
}
