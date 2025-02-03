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
    uint256 public totalLiquidityShares;
    mapping(address => uint256) public liquidityShares;

    uint256 public constant SWAP_FEE = 200; // 2% en basis points (10000 = 100%)

    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB, uint256 shares);
    event LiquidityRemoved(address indexed user, uint256 amountA, uint256 amountB, uint256 shares);
    event SwapExecuted(address indexed user, uint256 amountIn, uint256 amountOut, address tokenIn, address tokenOut, uint256 fee);

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

        // Initialisation des parts de liquidité
        totalLiquidityShares = _amountA + _amountB;
        liquidityShares[_creator] = totalLiquidityShares;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Transfer failed for Token A");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "Transfer failed for Token B");

        uint256 newShares = amountA + amountB;
        liquidityShares[msg.sender] += newShares;
        totalLiquidityShares += newShares;

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, newShares);
    }

    function removeLiquidity(uint256 shares) external {
        require(shares > 0, "Shares must be > 0");
        require(liquidityShares[msg.sender] >= shares, "Insufficient shares");

        uint256 amountA = (shares * reserveA) / totalLiquidityShares;
        uint256 amountB = (shares * reserveB) / totalLiquidityShares;

        liquidityShares[msg.sender] -= shares;
        totalLiquidityShares -= shares;

        reserveA -= amountA;
        reserveB -= amountB;

        require(IERC20(tokenA).transfer(msg.sender, amountA), "Transfer failed for Token A");
        require(IERC20(tokenB).transfer(msg.sender, amountB), "Transfer failed for Token B");

        emit LiquidityRemoved(msg.sender, amountA, amountB, shares);
    }

    function swap(address tokenIn, uint256 amountIn) external {
        require(tokenIn == tokenA || tokenIn == tokenB, "Invalid token");

        address tokenOut = (tokenIn == tokenA) ? tokenB : tokenA;
        uint256 reserveIn = (tokenIn == tokenA) ? reserveA : reserveB;
        uint256 reserveOut = (tokenIn == tokenA) ? reserveB : reserveA;

        require(amountIn > 0, "Amount must be > 0");
        require(reserveIn + amountIn > 0, "Invalid reserves");

        // Calcul du frais de swap (2%)
        uint256 fee = (amountIn * SWAP_FEE) / 10000;
        uint256 amountInAfterFee = amountIn - fee;

        // Calcul du montant de sortie
        uint256 amountOut = (amountInAfterFee * reserveOut) / (reserveIn + amountInAfterFee);
        require(amountOut > 0, "Swap amount too low");

        // Mise à jour des réserves
        if (tokenIn == tokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        // Distribuer les frais aux LPs
        distributeFees(fee, tokenIn);

        // Effectuer le transfert des tokens
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
        require(IERC20(tokenOut).transfer(msg.sender, amountOut), "Transfer failed");

        emit SwapExecuted(msg.sender, amountIn, amountOut, tokenIn, tokenOut, fee);
    }

    function distributeFees(uint256 fee, address tokenIn) internal {
        if (totalLiquidityShares == 0) return;

        // Ajoute le montant des frais aux réserves
        if (tokenIn == tokenA) {
            reserveA += fee;
        } else {
            reserveB += fee;
        }
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function getLiquidityRatio() external view returns (uint256) {
        require(reserveB > 0, "Division by zero");
        return (reserveA * 1e18) / reserveB;
    }
}
