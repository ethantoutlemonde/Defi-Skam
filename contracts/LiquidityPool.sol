// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PoolToken.sol";
import "./ErrorLibrary.sol";

contract LiquidityPool {
    address public tokenA;
    address public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;
    PoolToken public lpToken;
    address public treasury;

    uint256 public constant SWAP_FEE = 200; // 2% de frais en basis points
    uint256 public constant LIQUIDITY_FEE = 100; // 1% pour les LP
    uint256 public constant TREASURY_FEE = 100; // 1% pour la trésorerie

    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed user, uint256 lpBurned, uint256 amountA, uint256 amountB, uint256 feesShare);
    event SwapExecuted(address indexed user, uint256 amountIn, uint256 amountOut, address tokenIn, address tokenOut, uint256 fee);

    constructor(address _tokenA, address _tokenB, address _treasury) {
        require(_tokenA != _tokenB, ErrorLibrary.TOKENS_MUST_BE_DIFFERENT());
        tokenA = _tokenA;
        tokenB = _tokenB;
        treasury = _treasury;
        lpToken = new PoolToken("Pool LP Token", "PLP");
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, ErrorLibrary.AMOUNTS_MUST_BE_GREATER_THAN_ZERO());

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        uint256 lpMinted;
        if (reserveA == 0 && reserveB == 0) {
            lpMinted = amountA + amountB;
        } else {
            lpMinted = (amountA + amountB) * lpToken.totalSupply() / (reserveA + reserveB);
        }

        reserveA += amountA;
        reserveB += amountB;
        lpToken.mint(msg.sender, lpMinted);

        emit LiquidityAdded(msg.sender, amountA, amountB, lpMinted);
    }

    function removeLiquidity(uint256 lpAmount) external {
        require(lpAmount > 0, ErrorLibrary.LP_AMOUNT_MUST_BE_GREATER_THAN_ZERO());
        require(lpToken.balanceOf(msg.sender) >= lpAmount, ErrorLibrary.INSUFFICIENT_LP_BALANCE());

        uint256 amountA = (lpAmount * reserveA) / lpToken.totalSupply();
        uint256 amountB = (lpAmount * reserveB) / lpToken.totalSupply();
        uint256 feesShare = (lpAmount * (reserveA + reserveB) * LIQUIDITY_FEE) / (lpToken.totalSupply() * 10000);

        reserveA -= amountA;
        reserveB -= amountB;
        lpToken.burn(msg.sender, lpAmount);

        IERC20(tokenA).transfer(msg.sender, amountA + feesShare);
        IERC20(tokenB).transfer(msg.sender, amountB + feesShare);

        emit LiquidityRemoved(msg.sender, lpAmount, amountA, amountB, feesShare);
    }

    function swap(address tokenIn, uint256 amountIn) external {
        require(tokenIn == tokenA || tokenIn == tokenB, ErrorLibrary.INVALID_TOKEN());

        address tokenOut = (tokenIn == tokenA) ? tokenB : tokenA;
        uint256 reserveIn = (tokenIn == tokenA) ? reserveA : reserveB;
        uint256 reserveOut = (tokenIn == tokenA) ? reserveB : reserveA;

        require(amountIn > 0, ErrorLibrary.AMOUNT_MUST_BE_GREATER_THAN_ZERO());
        require(reserveIn + amountIn > 0, ErrorLibrary.INVALID_RESERVES());

        uint256 fee = (amountIn * SWAP_FEE) / 10000;
        uint256 liquidityFee = (fee * LIQUIDITY_FEE) / SWAP_FEE;
        uint256 treasuryFee = (fee * TREASURY_FEE) / SWAP_FEE;
        uint256 amountInAfterFee = amountIn - fee;

        uint256 amountOut = (amountInAfterFee * reserveOut) / (reserveIn + amountInAfterFee);
        require(amountOut > 0, ErrorLibrary.SWAP_AMOUNT_TOO_LOW());

        if (tokenIn == tokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        distributeFees(liquidityFee, treasuryFee, tokenIn);

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        emit SwapExecuted(msg.sender, amountIn, amountOut, tokenIn, tokenOut, fee);
    }

    function distributeFees(uint256 liquidityFee, uint256 treasuryFee, address tokenIn) internal {
        if (totalLiquidityShares() == 0) return;

        IERC20(tokenIn).transfer(treasury, treasuryFee);

        if (tokenIn == tokenA) {
            reserveA += liquidityFee;
        } else {
            reserveB += liquidityFee;
        }
    }

    function totalLiquidityShares() public view returns (uint256) {
        return lpToken.totalSupply();
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function getLiquidityRatio() external view returns (uint256) {
        require(reserveB > 0, ErrorLibrary.DIVISION_BY_ZERO());
        return (reserveA * 1e18) / reserveB;
    }
}
