// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SafeBurnReflect is ERC20, Ownable {
    // Constants
    uint256 public constant TOTAL_SUPPLY = 100000000000 * 10**18; // 100 billion tokens

    // Reward work outs
    uint256 public constant TRUEBURN_PERCENTAGE = 1;
    uint256 public constant LP_PERCENTAGE = 1;
    uint256 public constant TREASURY_PERCENTAGE = 4;

    // Addresses to send to
    address public trueburnWallet;
    address public lpWallet;
    address public treasuryWallet;

    // Construct
    constructor(
        address _trueburnWallet,
        address _lpWallet,
        address _treasuryWallet
    ) ERC20("Safe Burn Reflect", "SBR") {
        trueburnWallet = _trueburnWallet;
        lpWallet = _lpWallet;
        treasuryWallet = _treasuryWallet;

        _mint(owner(), TOTAL_SUPPLY);
    }

    // Trueburn function
    function trueburn(uint256 amount) external onlyOwner {
        uint256 trueburnAmount = (amount * TRUEBURN_PERCENTAGE) / 100;
        _burn(msg.sender, trueburnAmount);
    }

    // Transfer function overriding ERC20 transfer
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 lpAmount = (amount * LP_PERCENTAGE) / 100;
        uint256 treasuryAmount = (amount * TREASURY_PERCENTAGE) / 100;
        uint256 transferAmount = amount - lpAmount - treasuryAmount;

        require(
            amount == transferAmount + lpAmount + treasuryAmount,
            "Transfer amounts don't match"
        );

        // Transfer to recipient
        super._transfer(sender, recipient, transferAmount);

        // Transfer to LP and Treasury
        super._transfer(sender, lpWallet, lpAmount);
        super._transfer(sender, treasuryWallet, treasuryAmount);
    }
}
