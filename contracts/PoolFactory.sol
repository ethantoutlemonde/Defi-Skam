// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LiquidityPool {
    address public tokenA;
    address public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;
    address public creator;

    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed user, uint256 amountA, uint256 amountB);
    event SwapExecuted(address indexed user, uint256 amountIn, uint256 amountOut, address tokenIn, address tokenOut);

    constructor(address _tokenA, address _tokenB, uint256 _amountA, uint256 _amountB, address _creator) {
        require(_tokenA != _tokenB, "Tokens must be different");
        require(_amountA > 0 && _amountB > 0, "Initial liquidity must be > 0");

        tokenA = _tokenA;
        tokenB = _tokenB;
        reserveA = _amountA;
        reserveB = _amountB;
        creator = _creator;

        // Transférer les tokens du créateur au pool
        require(IERC20(tokenA).transferFrom(_creator, address(this), _amountA), "Transfer failed for Token A");
        require(IERC20(tokenB).transferFrom(_creator, address(this), _amountB), "Transfer failed for Token B");
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Transfer failed for Token A");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "Transfer failed for Token B");

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");
        require(reserveA >= amountA && reserveB >= amountB, "Insufficient liquidity");

        reserveA -= amountA;
        reserveB -= amountB;

        require(IERC20(tokenA).transfer(msg.sender, amountA), "Transfer failed for Token A");
        require(IERC20(tokenB).transfer(msg.sender, amountB), "Transfer failed for Token B");

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    function swap(address tokenIn, uint256 amountIn) external {
        require(tokenIn == tokenA || tokenIn == tokenB, "Invalid token");

        address tokenOut = (tokenIn == tokenA) ? tokenB : tokenA;
        uint256 reserveIn = (tokenIn == tokenA) ? reserveA : reserveB;
        uint256 reserveOut = (tokenIn == tokenA) ? reserveB : reserveA;

        require(amountIn > 0, "Amount must be > 0");
        require(reserveIn + amountIn > 0, "Invalid reserves");

        // Calcul du montant de sortie (simplifié, sans frais)
        uint256 amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);

        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
        require(IERC20(tokenOut).transfer(msg.sender, amountOut), "Transfer failed");

        // Mettre à jour les réserves
        if (tokenIn == tokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        emit SwapExecuted(msg.sender, amountIn, amountOut, tokenIn, tokenOut);
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function getLiquidityRatio() external view returns (uint256) {
        require(reserveB > 0, "Division by zero");
        return (reserveA * 1e18) / reserveB; // Ratio en base 1e18 pour éviter les décimales flottantes
    }
}
