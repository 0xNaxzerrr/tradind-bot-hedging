// test/TradingBot.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TradingBot.sol";
import "../src/utils/ImpermanentLossCalculator.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Tests for TradingBot
/// @notice Comprehensive test suite for TradingBot functionality
/// @dev Uses Foundry's testing framework
contract TradingBotTest is Test {
    // Contracts to test
    TradingBot public bot;
    ImpermanentLossCalculator public calculator;

    // Mock contracts
    MockERC20 public token0;
    MockERC20 public token1;
    MockUniswapV2Pair public pair;
    MockUniswapV2Router public router;

    // Test addresses
    address public owner = address(1);
    address public user = address(2);

    // Test values
    uint256 constant INITIAL_LIQUIDITY = 1000 ether;
    uint256 constant INITIAL_PRICE = 1000e18; // 1 ETH = 1000 USDC
    uint256 constant REBALANCE_THRESHOLD = 500; // 5% in basis points

    /// @notice Sets up the test environment
    function setUp() public {
        // Deploy mock tokens
        token0 = new MockERC20("Ethereum", "ETH");
        token1 = new MockERC20("USD Coin", "USDC");

        // Deploy mock Uniswap contracts
        pair = new MockUniswapV2Pair(address(token0), address(token1));
        router = new MockUniswapV2Router(address(pair));

        // Deploy main contracts
        calculator = new ImpermanentLossCalculator();
        bot = new TradingBot(
            address(calculator),
            address(pair),
            address(router),
            REBALANCE_THRESHOLD
        );

        // Setup initial balances and approvals
        vm.startPrank(owner);
        token0.mint(owner, 1000 ether);
        token1.mint(owner, 1000000 ether);
        token0.approve(address(bot), type(uint256).max);
        token1.approve(address(bot), type(uint256).max);
        vm.stopPrank();

        // Initialize pool with initial liquidity
        pair.setReserves(100 ether, 100000 ether);
    }

    /// @notice Test opening a position
    function testOpenPosition() public {
        uint256 token0Amount = 1 ether;
        uint256 token1Amount = 1000 ether;

        vm.startPrank(owner);
        bot.openPosition(token0Amount, token1Amount, 0);

        (uint256 amount0, uint256 amount1, , , bool isActive) = bot
            .currentPosition();
        assertTrue(isActive, "Position should be active");
        assertEq(amount0, token0Amount, "Incorrect token0 amount");
        assertEq(amount1, token1Amount, "Incorrect token1 amount");
        vm.stopPrank();
    }

    /// @notice Test opening position with insufficient balance
    function testFailOpenPositionInsufficientBalance() public {
        vm.startPrank(user); // User has no tokens
        bot.openPosition(1 ether, 1000 ether, 0);
        vm.stopPrank();
    }

    /// @notice Test opening position when one already exists
    function testFailOpenPositionAlreadyExists() public {
        vm.startPrank(owner);
        bot.openPosition(1 ether, 1000 ether, 0);
        bot.openPosition(1 ether, 1000 ether, 0); // Should fail
        vm.stopPrank();
    }

    /// @notice Test closing a position
    function testClosePosition() public {
        // First open a position
        vm.startPrank(owner);
        bot.openPosition(1 ether, 1000 ether, 0);

        // Then close it
        bot.closePosition(0, 0);

        (, , , , bool isActive) = bot.currentPosition();
        assertFalse(isActive, "Position should be inactive");
        vm.stopPrank();
    }

    /// @notice Test rebalancing check
    function testCheckRebalance() public {
        vm.startPrank(owner);
        bot.openPosition(1 ether, 1000 ether, 0);

        // Change price in pool to trigger rebalance
        pair.setReserves(80 ether, 100000 ether); // Price increased

        (bool needsRebalance, uint256 hedgeAmount) = bot.checkRebalance();
        assertTrue(needsRebalance, "Should need rebalancing");
        assertGt(hedgeAmount, 0, "Hedge amount should be greater than 0");
        vm.stopPrank();
    }

    /// @notice Test updating rebalance threshold
    function testUpdateRebalanceThreshold() public {
        uint256 newThreshold = 1000; // 10%
        vm.prank(owner);
        bot.updateRebalanceThreshold(newThreshold);
        assertEq(
            bot.rebalanceThreshold(),
            newThreshold,
            "Threshold not updated"
        );
    }

    /// @notice Test failing to update threshold with invalid value
    function testFailUpdateRebalanceThresholdInvalid() public {
        vm.prank(owner);
        bot.updateRebalanceThreshold(11000); // > 100%
    }
}

/// @notice Mock ERC20 token for testing
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @notice Mock Uniswap V2 Pair for testing
contract MockUniswapV2Pair {
    address public token0;
    address public token1;
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function setReserves(uint112 _reserve0, uint112 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = uint32(block.timestamp);
    }
}

/// @notice Mock Uniswap V2 Router for testing
contract MockUniswapV2Router {
    IUniswapV2Pair public pair;

    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
    }

    function addLiquidity(
        address,
        address,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256,
        uint256,
        address,
        uint256
    ) external pure returns (uint256, uint256, uint256) {
        return (amountADesired, amountBDesired, amountADesired);
    }

    function removeLiquidity(
        address,
        address,
        uint256,
        uint256 amountAMin,
        uint256 amountBMin,
        address,
        uint256
    ) external pure returns (uint256, uint256) {
        return (amountAMin, amountBMin);
    }
}
