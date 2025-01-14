// src/HedgingStrategy.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./utils/ImpermanentLossCalculator.sol";
import "./utils/PriceCalculator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Hedging Strategy for Impermanent Loss
/// @author 0xNaxzerrr
/// @notice Implements hedging strategies for Uniswap V2 LP positions
/// @dev Uses ImpermanentLossCalculator and PriceCalculator for decision making
contract HedgingStrategy is Ownable {
    /// @notice Calculator for impermanent loss
    ImpermanentLossCalculator public immutable ilCalculator;

    /// @notice Calculator for price data
    PriceCalculator public immutable priceCalculator;

    /// @notice Parameters for the hedging strategy
    struct StrategyParams {
        uint256 rebalanceThreshold; // Minimum price deviation to trigger rebalance
        uint256 maxHedgeRatio; // Maximum hedge ratio in basis points
        uint256 twapWindow; // Time window for TWAP calculation
        uint256 minRebalanceInterval; // Minimum time between rebalances
        bool isActive; // Whether the strategy is currently active
    }

    /// @notice Current strategy parameters
    StrategyParams public strategyParams;

    /// @notice Timestamp of last rebalance
    uint256 public lastRebalanceTime;

    /// @notice Event emitted when strategy parameters are updated
    event StrategyParamsUpdated(
        uint256 rebalanceThreshold,
        uint256 maxHedgeRatio,
        uint256 twapWindow,
        uint256 minRebalanceInterval
    );

    /// @notice Event emitted when a hedge signal is generated
    event HedgeSignalGenerated(
        bool shouldHedge,
        uint256 hedgeAmount,
        uint256 currentPrice,
        uint256 timestamp
    );

    /// @notice Constructor initializes the contract with required components
    /// @param _ilCalculator Address of ImpermanentLossCalculator
    /// @param _priceCalculator Address of PriceCalculator
    constructor(
        address _ilCalculator,
        address _priceCalculator
    ) Ownable(msg.sender) {
        ilCalculator = ImpermanentLossCalculator(_ilCalculator);
        priceCalculator = PriceCalculator(_priceCalculator);

        // Set default strategy parameters
        strategyParams = StrategyParams({
            rebalanceThreshold: 500, // 5%
            maxHedgeRatio: 10000, // 100%
            twapWindow: 1 hours,
            minRebalanceInterval: 1 hours,
            isActive: false
        });
    }

    /// @notice Updates strategy parameters
    /// @param _rebalanceThreshold New rebalance threshold in basis points
    /// @param _maxHedgeRatio New maximum hedge ratio in basis points
    /// @param _twapWindow New TWAP window in seconds
    /// @param _minRebalanceInterval New minimum rebalance interval in seconds
    function updateStrategyParams(
        uint256 _rebalanceThreshold,
        uint256 _maxHedgeRatio,
        uint256 _twapWindow,
        uint256 _minRebalanceInterval
    ) external onlyOwner {
        require(_rebalanceThreshold <= 10000, "Invalid threshold");
        require(_maxHedgeRatio <= 10000, "Invalid hedge ratio");
        require(_twapWindow > 0, "Invalid TWAP window");
        require(_minRebalanceInterval > 0, "Invalid rebalance interval");

        strategyParams.rebalanceThreshold = _rebalanceThreshold;
        strategyParams.maxHedgeRatio = _maxHedgeRatio;
        strategyParams.twapWindow = _twapWindow;
        strategyParams.minRebalanceInterval = _minRebalanceInterval;

        emit StrategyParamsUpdated(
            _rebalanceThreshold,
            _maxHedgeRatio,
            _twapWindow,
            _minRebalanceInterval
        );
    }

    /// @notice Evaluates whether hedging is needed and calculates hedge amount
    /// @param pair Address of Uniswap V2 pair
    /// @param position Current pool position
    /// @return shouldHedge Whether hedging is needed
    /// @return hedgeAmount Amount to hedge if needed
    function evaluateHedging(
        address pair,
        ImpermanentLossCalculator.PoolPosition memory position
    ) external returns (bool shouldHedge, uint256 hedgeAmount) {
        require(strategyParams.isActive, "Strategy not active");
        require(
            block.timestamp >=
                lastRebalanceTime + strategyParams.minRebalanceInterval,
            "Rebalance interval not elapsed"
        );

        // Check price deviation
        bool priceDeviationExceeded = priceCalculator.isPriceDeviationExceeded(
            pair,
            strategyParams.rebalanceThreshold,
            strategyParams.twapWindow
        );

        if (!priceDeviationExceeded) {
            return (false, 0);
        }

        // Calculate hedge amount
        hedgeAmount = ilCalculator.calculateHedgeAmount(pair, position);

        // Apply maximum hedge ratio
        uint256 maxHedge = (position.token0Amount *
            strategyParams.maxHedgeRatio) / 10000;
        hedgeAmount = hedgeAmount > maxHedge ? maxHedge : hedgeAmount;

        shouldHedge = hedgeAmount > 0;

        if (shouldHedge) {
            lastRebalanceTime = block.timestamp;
            emit HedgeSignalGenerated(
                true,
                hedgeAmount,
                priceCalculator.getSpotPrice(pair),
                block.timestamp
            );
        }
    }

    /// @notice Activates or deactivates the strategy
    /// @param _isActive New active status
    function setStrategyActive(bool _isActive) external onlyOwner {
        strategyParams.isActive = _isActive;
    }
}
