// src/TradingBot.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./utils/ImpermanentLossCalculator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Trading Bot for Hedging Impermanent Loss
/// @author 0xNaxzerrr
/// @notice Manages LP positions and hedging strategy for Uniswap V2 pools
/// @dev Implements IL hedging strategy using ImpermanentLossCalculator
contract TradingBot is Ownable, ReentrancyGuard {
    /// @notice Calculator contract for impermanent loss
    ImpermanentLossCalculator public immutable ilCalculator;

    /// @notice Uniswap V2 pool being monitored
    IUniswapV2Pair public pool;

    /// @notice Router contract for Uniswap interactions
    IUniswapV2Router public router;

    /// @notice Minimum threshold for rebalancing (in basis points)
    uint256 public rebalanceThreshold;

    /// @notice Struct to track current trading position
    struct Position {
        uint256 token0Amount;
        uint256 token1Amount;
        uint256 initialPrice;
        uint256 lastUpdateTime;
        bool isActive;
    }

    /// @notice Current position in the pool
    Position public currentPosition;

    /// @notice Event emitted when position is opened
    event PositionOpened(
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 initialPrice,
        uint256 timestamp
    );

    /// @notice Event emitted when position is closed
    event PositionClosed(
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 finalPrice,
        uint256 timestamp
    );

    /// @notice Event emitted when hedge is rebalanced
    event HedgeRebalanced(
        uint256 oldHedgeAmount,
        uint256 newHedgeAmount,
        uint256 timestamp
    );

    /// @notice Event emitted when pool is updated
    event PoolUpdated(address indexed oldPool, address indexed newPool);

    /// @notice Event emitted when router is updated
    event RouterUpdated(address indexed oldRouter, address indexed newRouter);

    /// @notice Constructor initializes the contract with required addresses
    /// @param _ilCalculator Address of ImpermanentLossCalculator contract
    /// @param _pool Address of initial Uniswap V2 pool
    /// @param _router Address of initial Uniswap V2 router
    /// @param _rebalanceThreshold Initial rebalance threshold in basis points
    constructor(
        address _ilCalculator,
        address _pool,
        address _router,
        uint256 _rebalanceThreshold
    ) Ownable(msg.sender) {
        require(_ilCalculator != address(0), "Invalid calculator address");
        require(_pool != address(0), "Invalid pool address");
        require(_router != address(0), "Invalid router address");

        ilCalculator = ImpermanentLossCalculator(_ilCalculator);
        pool = IUniswapV2Pair(_pool);
        router = IUniswapV2Router(_router);
        rebalanceThreshold = _rebalanceThreshold;
    }

    /// @notice Updates the pool address
    /// @param _newPool Address of the new Uniswap V2 pool
    function updatePool(address _newPool) external onlyOwner {
        require(_newPool != address(0), "Invalid pool address");
        address oldPool = address(pool);
        pool = IUniswapV2Pair(_newPool);
        emit PoolUpdated(oldPool, _newPool);
    }

    /// @notice Updates the router address
    /// @param _newRouter Address of the new Uniswap V2 router
    function updateRouter(address _newRouter) external onlyOwner {
        require(_newRouter != address(0), "Invalid router address");
        address oldRouter = address(router);
        router = IUniswapV2Router(_newRouter);
        emit RouterUpdated(oldRouter, _newRouter);
    }

    /// @notice Opens a new LP position
    /// @param token0Amount Amount of token0 to provide
    /// @param token1Amount Amount of token1 to provide
    /// @param minLiquidity Minimum liquidity tokens to receive
    function openPosition(
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 minLiquidity
    ) external onlyOwner nonReentrant {
        require(!currentPosition.isActive, "Position already exists");
        require(token0Amount > 0 && token1Amount > 0, "Invalid amounts");

        // Transfer tokens from owner
        IERC20(pool.token0()).transferFrom(
            msg.sender,
            address(this),
            token0Amount
        );
        IERC20(pool.token1()).transferFrom(
            msg.sender,
            address(this),
            token1Amount
        );

        // Approve router for token transfers
        IERC20(pool.token0()).approve(address(router), token0Amount);
        IERC20(pool.token1()).approve(address(router), token1Amount);

        // Add liquidity to Uniswap
        (uint256 amount0, uint256 amount1, uint256 liquidity) = router
            .addLiquidity(
                pool.token0(),
                pool.token1(),
                token0Amount,
                token1Amount,
                (token0Amount * 95) / 100, // 5% slippage
                (token1Amount * 95) / 100, // 5% slippage
                address(this),
                block.timestamp
            );

        require(liquidity >= minLiquidity, "Insufficient liquidity received");

        // Get current price
        (uint112 reserve0, uint112 reserve1, ) = pool.getReserves();
        uint256 initialPrice = (uint256(reserve1) * 1e18) / uint256(reserve0);

        // Update position
        currentPosition = Position({
            token0Amount: amount0,
            token1Amount: amount1,
            initialPrice: initialPrice,
            lastUpdateTime: block.timestamp,
            isActive: true
        });

        emit PositionOpened(amount0, amount1, initialPrice, block.timestamp);
    }

    /// @notice Closes the current LP position
    /// @param minToken0Amount Minimum amount of token0 to receive
    /// @param minToken1Amount Minimum amount of token1 to receive
    function closePosition(
        uint256 minToken0Amount,
        uint256 minToken1Amount
    ) external onlyOwner nonReentrant {
        require(currentPosition.isActive, "No active position");

        // Get LP token balance
        uint256 liquidity = IERC20(address(pool)).balanceOf(address(this));
        require(liquidity > 0, "No liquidity to remove");

        // Approve router for LP token
        IERC20(address(pool)).approve(address(router), liquidity);

        // Remove liquidity
        (uint256 amount0, uint256 amount1) = router.removeLiquidity(
            pool.token0(),
            pool.token1(),
            liquidity,
            minToken0Amount,
            minToken1Amount,
            msg.sender,
            block.timestamp
        );

        // Get final price
        (uint112 reserve0, uint112 reserve1, ) = pool.getReserves();
        uint256 finalPrice = (uint256(reserve1) * 1e18) / uint256(reserve0);

        emit PositionClosed(amount0, amount1, finalPrice, block.timestamp);

        // Reset position
        delete currentPosition;
    }

    /// @notice Checks if hedging position needs rebalancing
    /// @return requiresRebalance True if rebalancing is needed
    /// @return newHedgeAmount Required hedge amount if rebalancing is needed
    function checkRebalance()
        public
        view
        returns (bool requiresRebalance, uint256 newHedgeAmount)
    {
        if (!currentPosition.isActive) return (false, 0);

        // Convert position to calculator format
        ImpermanentLossCalculator.PoolPosition
            memory position = ImpermanentLossCalculator.PoolPosition({
                token0Amount: currentPosition.token0Amount,
                token1Amount: currentPosition.token1Amount,
                initialPrice: currentPosition.initialPrice,
                initialLiquidity: IERC20(address(pool)).balanceOf(address(this))
            });

        // Calculate required hedge
        newHedgeAmount = ilCalculator.calculateHedgeAmount(
            address(pool),
            position
        );

        // Get current hedge position from Binance (to be implemented)
        uint256 currentHedge = getCurrentHedgePosition();

        // Check if rebalancing is needed
        requiresRebalance = ilCalculator.needsRebalancing(
            currentHedge,
            newHedgeAmount,
            rebalanceThreshold
        );
    }

    /// @notice Updates the rebalance threshold
    /// @param _newThreshold New threshold in basis points
    function updateRebalanceThreshold(
        uint256 _newThreshold
    ) external onlyOwner {
        require(
            _newThreshold > 0 && _newThreshold <= 10000,
            "Invalid threshold"
        );
        rebalanceThreshold = _newThreshold;
    }

    /// @notice Gets current hedge position from Binance
    /// @dev To be implemented with Binance API integration
    /// @return hedgeAmount Current hedge position size
    function getCurrentHedgePosition()
        internal
        pure
        returns (uint256 hedgeAmount)
    {
        // TODO: Implement Binance API integration
        return 0;
    }

    /// @notice Executes hedge rebalancing on Binance
    /// @dev To be implemented with Binance API integration
    /// @param targetHedgeAmount Desired hedge position size
    function executeHedgeRebalance(uint256 targetHedgeAmount) internal {
        // TODO: Implement Binance API integration
        emit HedgeRebalanced(
            getCurrentHedgePosition(),
            targetHedgeAmount,
            block.timestamp
        );
    }
}
