// SPDX-License-Identifier: MIT

// Using openzeppelin contracts version 4.5 between 0.8.0 and 0.8.19 . chosen bc of familiarity
// v2 core and periphery from uniswap direct linking



// 0xb6A1D5E4607D83154d62aab339efFc2C036A014a // treasury address
// 0x581fA0Ee5A68a1Fe7c8Ad1Eb2bfdD9cF66d3d923 //router
// ["0x5B35A6Bd6091709a82D309451Ad02E3FCc8A9014", "0xb6A1D5E4607D83154d62aab339efFc2C036A014a"]

pragma solidity 0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/access/Ownable.sol";
import "https://github.com/Uniswap/v2-periphery/blob/0335e8f7e1bd1e8d8329fd300aea2ef2f36dd19f/contracts/interfaces/IUniswapV2Router02.sol#L5";
import "https://github.com/Uniswap/v2-core/blob/ee547b17853e71ed4e0101ccfd52e70d5acded58/contracts/interfaces/IUniswapV2Pair.sol";
import "https://github.com/Uniswap/v2-core/blob/ee547b17853e71ed4e0101ccfd52e70d5acded58/contracts/interfaces/IUniswapV2Factory.sol";

contract SafeAF is ERC20, Ownable {
    // Constants
    uint256 public constant TOTAL_SUPPLY = 100000000000 * 10**18; // 100 billion tokens

    // Reward work outs
    uint256 public TRUEBURN_PERCENTAGE = 1;
    uint256 public LP_PERCENTAGE = 1;
    uint256 public TREASURY_PERCENTAGE = 4;

    // Addresses to send to
    address public treasuryWallet;

    // Uniswap router and pair addresses
    IUniswapV2Router02 public uniswapRouter;
    address public uniswapPair;

    // Whitelist mapping
    mapping(address => bool) public whitelist;

    // Construct
    constructor(
        address _treasuryWallet,
        address _uniswapRouter,
        address[] memory initialWhitelist
    ) ERC20("Safe As Fuck", "SafeAF") {
        treasuryWallet = _treasuryWallet;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());

        _mint(owner(), TOTAL_SUPPLY);

        // Add initial addresses to the whitelist during deployment
        for (uint256 i = 0; i < initialWhitelist.length; i++) {
            whitelist[initialWhitelist[i]] = true;
        }
    }

    // Transfer function overriding ERC20 transfer
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // Check if the recipient is on the whitelist
        bool isWhitelisted = whitelist[recipient];

        uint256 lpAmount = isWhitelisted ? 0 : (amount * LP_PERCENTAGE) / 100;
        uint256 treasuryAmount = isWhitelisted ? 0 : (amount * TREASURY_PERCENTAGE) / 100;
        uint256 trueburnAmount = isWhitelisted ? 0 : (amount * TRUEBURN_PERCENTAGE) / 100;
        uint256 transferAmount = amount - lpAmount - treasuryAmount - trueburnAmount;

        require(
            amount == transferAmount + lpAmount + treasuryAmount + trueburnAmount,
            "Transfer amounts don't match"
        );

        // Transfer to recipient
        super._transfer(sender, recipient, transferAmount);

        // Transfer to Treasury and Trueburn
        super._transfer(sender, treasuryWallet, treasuryAmount);
        _burn(sender, trueburnAmount);  // Burning on transaction

        // Convert tokens to LP and add liquidity
        _convertToLP(lpAmount, sender);
    }

    // Function to convert tokens to LP and add liquidity
    function _convertToLP(uint256 amount, address sender) internal {
        // Approve the router to spend tokens
        _approve(sender, address(uniswapRouter), amount);

        // Convert tokens to ETH
        uniswapRouter.swapExactTokensForETH(
            amount,
            0, // Accept any amount of ETH
            getPathForTokens(address(this), uniswapRouter.WETH()),
            address(this),
            block.number // Use block number instead of timestamp
        );

        // Get the ETH balance
        uint256 ethBalance = address(this).balance;

        // Add liquidity
        uniswapRouter.addLiquidityETH{value: ethBalance}(
            address(this),
            amount,
            0, // slippage is acceptable
            0, // slippage is acceptable
            owner(), // LP tokens are sent to the owner
            block.number // Use block number instead of timestamp
        );
    }

    // Function to get the conversion path from token to ETH
    function getPathForTokens(address token, address weth) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = token;
        path[1] = weth;
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

    // Function to set Trueburn percentage, can be called only by the owner
    function setTrueburnPercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "Percentage should be less than or equal to 100");
        TRUEBURN_PERCENTAGE = percentage;
    }

    // Function to set LP percentage, can be called only by the owner
    function setLPPercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "Percentage should be less than or equal to 100");
        LP_PERCENTAGE = percentage;
    }

    // Function to set Treasury percentage, can be called only by the owner
    function setTreasuryPercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "Percentage should be less than or equal to 100");
        TREASURY_PERCENTAGE = percentage;
    }

    // Function to add an address to the whitelist, can be called only by the owner
    function addToWhitelist(address account) external onlyOwner {
        whitelist[account] = true;
    }

    // Function to remove an address from the whitelist, can be called only by the owner
    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
    }

    // Function to allow anyone to burn their tokens
    function trueburn(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= balanceOf(msg.sender), "Insufficient balance");

        _burn(msg.sender, amount);
    }
}
