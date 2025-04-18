// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Linear is ERC20, Ownable {
    uint256 public constant INITIAL_PRICE = 0.000001 ether; // Starting price
    uint256 public constant M = 10**15; // Linear slope factor (price increase per token)
    uint256 public constant MAX_SUPPLY = 10_000_000_000 * 10**18; // 10 billion tokens
    
    // Reserve pool for the bonding curve
    uint256 public reservePool;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {
        // Set the deployer as the initial owner
        transferOwnership(msg.sender);
    }

    // Calculate token price based on current supply using linear formula
    function calculateCurrentPrice() public view returns (uint256) {
        uint256 supply = totalSupply();
        // Price increases linearly with supply
        return INITIAL_PRICE + (supply * M) / 10**18;
    }

    // Calculate how many tokens you get for a specific amount of ETH
    function getTokenAmount(uint256 etherAmount) public view returns (uint256) {
        require(etherAmount > 0, "Amount must be greater than 0");
        
        uint256 currentPrice = calculateCurrentPrice();
        return (etherAmount * 10**18) / currentPrice;
    }

    // Buy tokens through the bonding curve
    function buyTokens() external payable {
        require(msg.value > 0, "Must send ETH to buy tokens");
        
        uint256 tokensToBuy = getTokenAmount(msg.value);
        require(totalSupply() + tokensToBuy <= MAX_SUPPLY, "Would exceed max supply");
        
        // Add ETH to reserve pool
        reservePool += msg.value;
        
        // Mint tokens to buyer
        _mint(msg.sender, tokensToBuy);
    }

    // Sell tokens back to the curve
    function sellTokens(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // Calculate ETH to return based on current price
        uint256 currentPrice = calculateCurrentPrice();
        uint256 ethToReturn = (amount * currentPrice) / 10**18;
        
        require(ethToReturn <= reservePool, "Not enough ETH in reserve");
        
        // Burn the tokens
        _burn(msg.sender, amount);
        
        // Reduce reserve pool
        reservePool -= ethToReturn;
        
        // Send ETH to seller
        payable(msg.sender).transfer(ethToReturn);
    }

    // View function to see how much ETH you would get for selling tokens
    function getSellValueInEth(uint256 amount) external view returns (uint256) {
        uint256 currentPrice = calculateCurrentPrice();
        return (amount * currentPrice) / 10**18;
    }
}
