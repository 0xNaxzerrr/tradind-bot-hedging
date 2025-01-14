// src/utils/ImpermanentLossCalculator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IUniswapV2Pair.sol";

/**
@title Impermanent Loss Calculator for Uniswap V2 LP positions
@author 0xNaxzerrr
@notice Calculates impermanent loss and optimal hedge positions for LP tokens
@dev Uses fixed point arithmetic with 18 decimal places for precision
*/

contract ImpermanentLossCalculator {
    /// @notice Precision for decimal calculations (18 decimals)
    uint256 constant PRECISION = 1e18;
    /// @notice Precision for square root calculations (9 decimals)
    uint256 constant SQRT_PRECISION = 1e9;

    /**
     @notice Struct to store LP position details
     @param token0Amount Amount of token0 in the position
     @param token1Amount Amount of token1 in the position
     @param initialPrice Initial price when position was opened
     @param initialLiquidity Initial liquidity provided
     */
    struct PoolPosition {
        uint256 token0Amount;
        uint256 token1Amount;
        uint256 initialPrice;
        uint256 initialLiquidity;
    }

    /**
    @notice Calculates the impermanent loss based on price change
    @dev Uses the formula: IL = 2 * sqrt(priceRatio) / (1 + priceRatio) - 1
    @param initialPrice The price when the position was opened
    @param currentPrice The current price
    @param liquidityProvided The amount of liquidity provided
    @return impermanentLoss The IL as a percentage (multiplied by PRECISION)
    */
    function calculateImpermanentLoss(
        uint256 initialPrice,
        uint256 currentPrice,
        uint256 liquidityProvided
    ) public pure returns (uint256 impermanentLoss) {
        if (initialPrice == currentPrice) return 0;

        // Calculate price ratio
        uint256 priceRatio = (currentPrice * PRECISION) / initialPrice;

        // Calculate square root of price ratio
        uint256 sqrtPriceRatio = sqrt(priceRatio);

        // Calculate IL using the formula
        uint256 numerator = 2 * sqrtPriceRatio;
        uint256 denominator = PRECISION + priceRatio;

        impermanentLoss = (numerator * PRECISION) / denominator - PRECISION;
    }

    /**
    @notice Calculates the optimal hedge amount for a given position
    @dev Fetches current reserves from Uniswap pool to determine current price
    @param pool Address of the Uniswap V2 pool
    @param position Current position in the pool
    @return hedgeAmount Amount that should be hedged
    */
    function calculateHedgeAmount(
        address pool,
        PoolPosition memory position
    ) external view returns (uint256 hedgeAmount) {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pool)
            .getReserves();

        // Calculate current price from reserves
        uint256 currentPrice = (uint256(reserve1) * PRECISION) /
            uint256(reserve0);

        // Calculate impermanent loss
        uint256 il = calculateImpermanentLoss(
            position.initialPrice,
            currentPrice,
            position.initialLiquidity
        );

        // Hedge amount is proportional to IL
        hedgeAmount = (position.token0Amount * il) / PRECISION;
    }

    /**
    @notice Utility function to calculate square root
    @dev Uses modified Newton-Raphson method
    @param x Number to find square root of
    @return y Approximate square root with SQRT_PRECISION decimals
    */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;

        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }

        return y * SQRT_PRECISION;
    }

    /**  
    @notice Calculates total position value in terms of token0
    @param position Current pool position
    @param currentPrice Current price of token1 in terms of token0
    @return totalValue Total position value in token0 units
    */
    function calculateTotalValue(
        PoolPosition memory position,
        uint256 currentPrice
    ) public pure returns (uint256 totalValue) {
        // Value in token0
        uint256 token0Value = position.token0Amount;

        // Convert token1 value to token0
        uint256 token1ValueInToken0 = (position.token1Amount * PRECISION) /
            currentPrice;

        totalValue = token0Value + token1ValueInToken0;
    }

    /** 
    @notice Determines if hedge position needs rebalancing
    @dev Compares current hedge with required hedge considering threshold
    @param currentHedge Current hedge position size
    @param requiredHedge Required hedge position size
    @param threshold Rebalancing threshold (percentage multiplied by PRECISION)
    @return needsRebalancing True if rebalancing is needed
    */
    function needsRebalancing(
        uint256 currentHedge,
        uint256 requiredHedge,
        uint256 threshold
    ) public pure returns (bool) {
        if (currentHedge == 0) return requiredHedge > 0;

        uint256 difference;
        if (currentHedge > requiredHedge) {
            difference = currentHedge - requiredHedge;
        } else {
            difference = requiredHedge - currentHedge;
        }

        return (difference * PRECISION) / currentHedge > threshold;
    }

    /**
    @notice Emitted when a new hedge calculation is performed
    @param timestamp Time of calculation
    @param currentHedge Current hedge amount
    @param requiredHedge Required hedge amount
    @param impermanentLoss Calculated IL
    */
    event HedgeCalculated(
        uint256 timestamp,
        uint256 currentHedge,
        uint256 requiredHedge,
        uint256 impermanentLoss
    );
}
