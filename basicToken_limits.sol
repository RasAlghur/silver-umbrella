// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts@5.1.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.1.0/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    uint8 private _decimals;
    uint256 public maxWalletSize;
    uint256 public maxTxnAmount;
    uint256 maxSupply;

    error MaxTxnAmountExceeded(uint256 amount);
    error MaxWalletSizeExceeded(uint256 amount);
    error LessThanRequired();

    event WalletSizeUpdated(uint256 previous, uint256 newWalletSize);
    event TxnSizeUpdated(uint256 previous, uint256 newTxnSize);
    event LimitsUpdated(uint256 newMaxTxnAmount, uint256 newMaxWalletSize);

    constructor(
        address initialOwner,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        uint256 totalSupply,
        uint256 maxWalletPercentage,
        uint256 maxWalletDivisor,
        uint256 maxTxnPercentage,
        uint256 maxTxnDivisor
    ) ERC20(tokenName, tokenSymbol) Ownable(initialOwner) {
        _decimals = tokenDecimals;
        maxSupply = totalSupply * 10**_decimals;
        maxTxnAmount = (maxTxnPercentage * maxSupply) / maxTxnDivisor;
        maxWalletSize = (maxWalletPercentage * maxSupply) / maxWalletDivisor;
        _mint(initialOwner, maxSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function updateLimits(
        uint256 maxTxnPercentage,
        uint256 maxTxnDivisor,
        uint256 maxWalletPercentage,
        uint256 maxWalletDivisor
    ) external onlyOwner {
        uint256 checkTxn = (maxTxnPercentage * maxSupply) / maxTxnDivisor;
        uint256 checkWallet = (maxWalletPercentage * maxSupply) / maxWalletDivisor;

        // Ensure maxTxnAmount is higher than 0.1% and maxWalletSize is higher than 1% of maxSupply
        if (checkTxn < maxSupply / 1000 || checkWallet < maxSupply / 100) {
            revert LessThanRequired();
        }

        maxTxnAmount = checkTxn;
        maxWalletSize = checkWallet;

        emit LimitsUpdated(maxTxnAmount, maxWalletSize);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead)
        ) {
            if (value > maxTxnAmount) {
                revert MaxTxnAmountExceeded(value);
            }
            uint256 holdings = balanceOf(to) + value;
            if (holdings > maxWalletSize) {
                revert MaxWalletSizeExceeded(value);
            }
        }
        super._update(from, to, value);
    }
}
