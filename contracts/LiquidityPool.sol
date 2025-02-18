// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PoolToken.sol";

contract LiquidityPool {        //mettre meme nom que fichier
    address public tokenA;
    address public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;
    PoolToken public lpToken;

    uint256 public constant SWAP_FEE = 200; // 2% de frais en basis points (10000 = 100%)

    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed user, uint256 lpBurned, uint256 amountA, uint256 amountB);
    event SwapExecuted(address indexed user, uint256 amountIn, uint256 amountOut, address tokenIn, address tokenOut, uint256 fee);

    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB, "Tokens must be different");
        tokenA = _tokenA;
        tokenB = _tokenB;
        lpToken = new PoolToken("Pool LP Token", "PLP");
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        uint256 lpMinted;
        if (reserveA == 0 && reserveB == 0) {
            lpMinted = amountA + amountB; // Première liquidité, pas de ratio
        } else {
            lpMinted = (amountA + amountB) * lpToken.totalSupply() / (reserveA + reserveB);
        }

        reserveA += amountA;
        reserveB += amountB;
        lpToken.mint(msg.sender, lpMinted);

        emit LiquidityAdded(msg.sender, amountA, amountB, lpMinted);
    }

    function removeLiquidity(uint256 lpAmount) external {
        require(lpAmount > 0, "LP amount must be > 0");
        require(lpToken.balanceOf(msg.sender) >= lpAmount, "Insufficient LP balance");

        uint256 amountA = (lpAmount * reserveA) / lpToken.totalSupply();
        uint256 amountB = (lpAmount * reserveB) / lpToken.totalSupply();

        reserveA -= amountA;
        reserveB -= amountB;
        lpToken.burn(msg.sender, lpAmount);

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, lpAmount, amountA, amountB);
    }

    function swap(address tokenIn, uint256 amountIn) external {
        require(tokenIn == tokenA || tokenIn == tokenB, "Invalid token");

        address tokenOut = (tokenIn == tokenA) ? tokenB : tokenA;
        uint256 reserveIn = (tokenIn == tokenA) ? reserveA : reserveB;
        uint256 reserveOut = (tokenIn == tokenA) ? reserveB : reserveA;

        require(amountIn > 0, "Amount must be > 0");
        require(reserveIn + amountIn > 0, "Invalid reserves");

        // Calcul des frais de swap (2%)
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

        // Ajoute les frais aux réserves
        distributeFees(fee, tokenIn);

        // Transferts des tokens
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        emit SwapExecuted(msg.sender, amountIn, amountOut, tokenIn, tokenOut, fee);
    }

    function distributeFees(uint256 fee, address tokenIn) internal {
        if (totalLiquidityShares() == 0) return;

        if (tokenIn == tokenA) {
            reserveA += fee;
        } else {
            reserveB += fee;
        }
    }

    function totalLiquidityShares() public view returns (uint256) {
        return lpToken.totalSupply();
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function getLiquidityRatio() external view returns (uint256) {
        require(reserveB > 0, "Division by zero");
        return (reserveA * 1e18) / reserveB;
    }
}
