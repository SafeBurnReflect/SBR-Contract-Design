// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/access/Ownable.sol";
// SafeBurnReflect
contract TrippleNipplePEPE  is ERC20, Ownable {
    // Constants
    uint256 public constant TOTAL_SUPPLY = 100000000000 * 10**18; // 100 billion tokens

    // Reward work outs
    uint256 public constant TRUEBURN_PERCENTAGE = 1;
    uint256 public constant LP_PERCENTAGE = 1;
    uint256 public constant TREASURY_PERCENTAGE = 4;

    // Addresses to send to
    address public lpWallet;
    address public treasuryWallet;

    // Construct
    constructor(
        address _lpWallet,
        address _treasuryWallet

    // ) ERC20("Safe Burn Reflect", "SBR") {
    ) ERC20("Tripple Nipple PEPE", "NIPSOUTPEPE") {
        lpWallet = _lpWallet;
        treasuryWallet = _treasuryWallet;

        _mint(owner(), TOTAL_SUPPLY);
    }

    // Transfer function overriding ERC20 transfer
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 lpAmount = (amount * LP_PERCENTAGE) / 100;
        uint256 treasuryAmount = (amount * TREASURY_PERCENTAGE) / 100;
        uint256 trueburnAmount = (amount * TRUEBURN_PERCENTAGE) / 100;
        uint256 transferAmount = amount - lpAmount - treasuryAmount - trueburnAmount;

        require(
            amount == transferAmount + lpAmount + treasuryAmount + trueburnAmount,
            "Transfer amounts don't match"
        );

        // Transfer to recipient
        super._transfer(sender, recipient, transferAmount);

        // Transfer to LP, Treasury, and Trueburn
        super._transfer(sender, lpWallet, lpAmount);
        super._transfer(sender, treasuryWallet, treasuryAmount);
        _burn(sender, trueburnAmount);  // Burning on transaction
    }

    // Function to recover ERC20 tokens mistakenly sent to the contract
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "Cannot recover the native token");
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    // Function to recover native tokens (ETH) mistakenly sent to the contract
    function recoverETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

}
