// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MyToken is ERC20, Ownable {
    // Custom errors
    error ZeroAddress();
    error DecimalsExceeded(uint8 provided);
    error ZeroTotalSupply();
    error CannotWithdrawNativeTokens();
    error NoTokenBalance();
    error ETHTransferFailed();

    using SafeERC20 for IERC20;

    uint8 private immutable _decimals;
    address payable private immutable initialOwner;

    event ForeignTokenWithdrawn(
        address indexed tokenAddress,
        address indexed withdrawer,
        uint256 amount
    );
    
    event ETHWithdrawn(
        address indexed withdrawer,
        uint256 amount
    );

    constructor(
        address _initialOwner,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        uint256 totalSupply
    ) ERC20(tokenName, tokenSymbol) Ownable(_initialOwner) {
        if (_initialOwner == address(0)) revert ZeroAddress();
        if (tokenDecimals > 18) revert DecimalsExceeded(tokenDecimals);
        if (totalSupply == 0) revert ZeroTotalSupply();

        _decimals = tokenDecimals;
        initialOwner = payable(_initialOwner);
        _mint(initialOwner, totalSupply * 10 ** _decimals);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function withdrawStuckETH() external {
        uint256 contractBalance = address(this).balance;
        if (contractBalance > 0) {
            (bool success, ) = initialOwner.call{value: contractBalance}("");
            if (!success) revert ETHTransferFailed();
            emit ETHWithdrawn(msg.sender, contractBalance);
        }
    }

    function withdrawForeignTokens(address _token) external {
        if (_token == address(0)) revert ZeroAddress();
        if (_token == address(this)) revert CannotWithdrawNativeTokens();

        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        if (tokenBalance == 0) revert NoTokenBalance();

        IERC20(_token).safeTransfer(initialOwner, tokenBalance);

        emit ForeignTokenWithdrawn(_token, msg.sender, tokenBalance);
    }
}
