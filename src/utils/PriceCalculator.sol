// src/utils/PriceCalculator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IUniswapV2Pair.sol";

/// @title Price Calculator for Uniswap V2 pairs
/// @author 0xNaxzerrr
/// @notice Provides utilities for price calculations and TWAP from Uniswap V2 pairs
/// @dev Uses Uniswap's time-weighted average price (TWAP) mechanism
contract PriceCalculator {
    /// @notice Precision for price calculations
    uint256 constant PRECISION = 1e18;

    /// @notice Stores the last price observation for a pair
    struct PriceObservation {
        uint256 timestamp;
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
    }

    /// @notice Maps pair addresses to their last price observation
    mapping(address => PriceObservation) public priceObservations;

    /// @notice Event emitted when a new price observation is recorded
    event PriceObserved(
        address indexed pair,
        uint256 price0Cumulative,
        uint256 price1Cumulative,
        uint256 timestamp
    );

    /// @notice Calculates the current spot price from reserves
    /// @param pair Address of the Uniswap V2 pair
    /// @return price Price of token0 in terms of token1
    function getSpotPrice(address pair) public view returns (uint256 price) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        require(reserve0 > 0 && reserve1 > 0, "Invalid reserves");
        
        price = (uint256(reserve1) * PRECISION) / uint256(reserve0);
    }

    /// @notice Updates price observation for a pair
    /// @param pair Address of the Uniswap V2 pair
    function updatePrice(address pair) external {
        IUniswapV2Pair uniswapPair = IUniswapV2Pair(pair);
        
        uint256 price0Cumulative = uniswapPair.price0CumulativeLast();
        uint256 price1Cumulative = uniswapPair.price1CumulativeLast();
        
        PriceObservation storage observation = priceObservations[pair];
        
        // Update the observation
        observation.timestamp = block.timestamp;
        observation.price0CumulativeLast = price0Cumulative;
        observation.price1CumulativeLast = price1Cumulative;
        
        emit PriceObserved(pair, price0Cumulative, price1Cumulative, block.timestamp);
    }

    /// @notice Calculates TWAP for a given time window
    /// @param pair Address of the Uniswap V2 pair
    /// @param timeWindow Time window in seconds for TWAP calculation
    /// @return twap Time-weighted average price
    function getTWAP(address pair, uint256 timeWindow) external view returns (uint256 twap) {
        require(timeWindow > 0, "Invalid time window");
        
        IUniswapV2Pair uniswapPair = IUniswapV2Pair(pair);
        PriceObservation storage observation = priceObservations[pair];
        
        require(observation.timestamp > 0, "No prior observation");
        require(block.timestamp >= observation.timestamp + timeWindow, "Insufficient time elapsed");
        
        uint256 price0Cumulative = uniswapPair.price0CumulativeLast();
        uint256 price1Cumulative = uniswapPair.price1CumulativeLast();
        
        uint256 timeElapsed = block.timestamp - observation.timestamp;
        
        uint256 price0Average = (price0Cumulative - observation.price0CumulativeLast) / timeElapsed;
        uint256 price1Average = (price1Cumulative - observation.price1CumulativeLast) / timeElapsed;
        
        // Use price0Average as it represents token1/token0 price
        twap = price0Average;
    }

    /// @notice Calculates volatility over a given time period
    /// @param pair Address of the Uniswap V2 pair
    /// @param timeWindow Time window in seconds
    /// @return volatility Price volatility as a percentage
    function calculateVolatility(
        address pair,
        uint256 timeWindow
    ) external view returns (uint256 volatility) {
        uint256 spotPrice = getSpotPrice(pair);
        uint256 twapPrice = this.getTWAP(pair, timeWindow);
        
        if (spotPrice > twapPrice) {
            volatility = ((spotPrice - twapPrice) * PRECISION) / twapPrice;
        } else {
            volatility = ((twapPrice - spotPrice) * PRECISION) / twapPrice;
        }
    }

    /// @notice Checks if the current price deviation exceeds a threshold
    /// @param pair Address of the Uniswap V2 pair
    /// @param threshold Maximum allowed deviation in basis points (1/10000)
    /// @param timeWindow Time window for TWAP calculation
    /// @return exceeded Whether the threshold was exceeded
    function isPriceDeviationExceeded(
        address pair,
        uint256 threshold,
        uint256 timeWindow
    ) external view returns (bool exceeded) {
        uint256 volatility = this.calculateVolatility(pair, timeWindow);
        exceeded = volatility > threshold;
    }
}