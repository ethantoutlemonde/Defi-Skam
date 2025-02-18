// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // Importation correcte de Chainlink
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

    AggregatorV3Interface internal priceFeedA;
    AggregatorV3Interface internal priceFeedB;

    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed user, uint256 lpBurned, uint256 amountA, uint256 amountB, uint256 feesShare);
    event SwapExecuted(address indexed user, uint256 amountIn, uint256 amountOut, address tokenIn, address tokenOut, uint256 fee);


    /**
     * @dev Initialise le contrat LiquidityPool avec les adresses des tokens, de la trésorerie et des price feeds Chainlink.
     * @param _tokenA Adresse du tokenA.
     * @param _tokenB Adresse du tokenB.
     * @param _treasury Adresse de la trésorerie.
     * @param _priceFeedA Adresse du price feed Chainlink pour le tokenA.
     * @param _priceFeedB Adresse du price feed Chainlink pour le tokenB.
     */
    constructor(address _tokenA, address _tokenB, address _treasury, address _priceFeedA, address _priceFeedB) {
        require(_tokenA != _tokenB, ErrorLibrary.TOKENS_MUST_BE_DIFFERENT());
        tokenA = _tokenA;
        tokenB = _tokenB;
        treasury = _treasury;
        lpToken = new PoolToken("Pool LP Token", "PLP");

        // Initialisation des price feeds Chainlink pour les tokens
        priceFeedA = AggregatorV3Interface(_priceFeedA);
        priceFeedB = AggregatorV3Interface(_priceFeedB);
    }


    /**
     * @dev Obtient le dernier prix du token donné à partir de son price feed Chainlink.
     * @param token L'adresse du token pour lequel obtenir le prix.
     * @return Le prix actuel du token en unités de base.
     */
    function getPrice(address token) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = (token == tokenA) ? priceFeedA : priceFeedB;
        (,int price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price feed");
        return uint256(price);
    }

    /**
     * @dev Vérifie si la slippage des prix dépasse un seuil acceptable avant d'effectuer un swap.
     * @param tokenIn L'adresse du token entrant dans le swap.
     * @param amountIn Le montant de tokens entrant dans le swap.
     */
    function checkPriceSlippage(address tokenIn, uint256 amountIn) internal view {
        uint256 priceIn = getPrice(tokenIn);
        uint256 priceOut = getPrice(tokenIn == tokenA ? tokenB : tokenA);

        uint256 amountOutExpected = (amountIn * priceIn) / priceOut;
        uint256 slippageThreshold = amountOutExpected / 100; // 1% de slippage max

        require(amountOutExpected > slippageThreshold, ErrorLibrary.PRICE_SLIPPAGE_TOO_HIGH());
    }

    /**
     * @dev Permet à un utilisateur d'ajouter de la liquidité au pool en déposant les deux tokens.
     * @param amountA Montant du tokenA à ajouter.
     * @param amountB Montant du tokenB à ajouter.
     */
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

     /**
     * @dev Permet à un utilisateur de retirer de la liquidité du pool en brûlant ses tokens LP.
     * @param lpAmount Le montant de tokens LP à brûler.
     */
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

    /**
     * @dev Permet à un utilisateur de swapper des tokens dans le pool.
     * @param tokenIn Le token entrant dans le swap (soit tokenA, soit tokenB).
     * @param amountIn Le montant de tokens entrant dans le swap.
     */
    function swap(address tokenIn, uint256 amountIn) external {
        require(tokenIn == tokenA || tokenIn == tokenB, ErrorLibrary.INVALID_TOKEN());

        checkPriceSlippage(tokenIn, amountIn);

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

    /**
     * @dev Distribution des frais de swap entre la trésorerie et la liquidité.
     * @param liquidityFee Frais destinés à la liquidité.
     * @param treasuryFee Frais destinés à la trésorerie.
     * @param tokenIn Le token utilisé pour la distribution des frais.
     */
    function distributeFees(uint256 liquidityFee, uint256 treasuryFee, address tokenIn) internal {
        if (totalLiquidityShares() == 0) return;

        IERC20(tokenIn).transfer(treasury, treasuryFee);

        if (tokenIn == tokenA) {
            reserveA += liquidityFee;
        } else {
            reserveB += liquidityFee;
        }
    }

    /**
     * @dev Renvoie le nombre total de parts de liquidité du pool.
     * @return Le nombre total de parts de liquidité.
     */
    function totalLiquidityShares() public view returns (uint256) {
        return lpToken.totalSupply();
    }

    /**
     * @dev Renvoie les réserves actuelles de tokenA et tokenB dans le pool.
     * @return Les réserves actuelles de tokenA et tokenB.
     */
    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    /**
     * @dev Renvoie le ratio de liquidité entre tokenA et tokenB.
     * @return Le ratio de liquidité.
     */
    function getLiquidityRatio() external view returns (uint256) {
        require(reserveB > 0, ErrorLibrary.DIVISION_BY_ZERO());
        return (reserveA * 1e18) / reserveB;
    }

    /**
     * @dev Renvoie la quantité de liquidité présente dans le pool pour chaque token.
     * @return La quantité de tokenA et tokenB dans le pool.
     */
    function getLiquidityInPool() external view returns (uint256, uint256){
        return (reserveA, reserveB);
    }
}
