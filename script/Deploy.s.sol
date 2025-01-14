// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/TradingBot.sol";
import "../src/utils/ImpermanentLossCalculator.sol";
import "../src/utils/PriceCalculator.sol";
import "../src/HedgingStrategy.sol";

contract DeployScript is Script {
    // Mock addresses for initial deployment
    address constant MOCK_PAIR = 0x4200000000000000000000000000000000000000;
    address constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deploying from address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy calculators first
        console.log("Deploying ImpermanentLossCalculator...");
        ImpermanentLossCalculator ilCalculator = new ImpermanentLossCalculator();
        console.log("ImpermanentLossCalculator deployed at:", address(ilCalculator));

        console.log("Deploying PriceCalculator...");
        PriceCalculator priceCalculator = new PriceCalculator();
        console.log("PriceCalculator deployed at:", address(priceCalculator));

        // 2. Deploy strategy
        console.log("Deploying HedgingStrategy...");
        HedgingStrategy strategy = new HedgingStrategy(
            address(ilCalculator),
            address(priceCalculator)
        );
        console.log("HedgingStrategy deployed at:", address(strategy));

        // 3. Deploy trading bot
        console.log("Deploying TradingBot...");
        TradingBot bot = new TradingBot(
            address(ilCalculator),
            MOCK_PAIR,
            UNISWAP_V2_ROUTER,
            500 // 5% rebalance threshold
        );
        console.log("TradingBot deployed at:", address(bot));

        vm.stopBroadcast();

        // Log all deployed addresses for reference
        console.log("\nDeployed Contracts Summary:");
        console.log("----------------------------");
        console.log("ImpermanentLossCalculator:", address(ilCalculator));
        console.log("PriceCalculator:", address(priceCalculator));
        console.log("HedgingStrategy:", address(strategy));
        console.log("TradingBot:", address(bot));
    }
}