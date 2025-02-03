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

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }
}

contract PoolFactory is Ownable (msg.sender) {
    struct PoolInfo {
        address poolAddress;
        address tokenA;
        address tokenB;
        uint256 reserveA;
        uint256 reserveB;
    }

    PoolInfo[] public pools;
    mapping(address => mapping(address => address)) public getPool; // tokenA => tokenB => pool address

    event PoolCreated(address indexed tokenA, address indexed tokenB, address poolAddress);

    function createPool(address _tokenA, address _tokenB, uint256 _amountA, uint256 _amountB) external {
        require(getPool[_tokenA][_tokenB] == address(0), "Pool already exists");

        LiquidityPool newPool = new LiquidityPool(_tokenA, _tokenB, _amountA, _amountB, msg.sender);
        PoolInfo memory newPoolInfo = PoolInfo(
            address(newPool),
            _tokenA,
            _tokenB,
            _amountA,
            _amountB
        );

        pools.push(newPoolInfo);
        getPool[_tokenA][_tokenB] = address(newPool);
        getPool[_tokenB][_tokenA] = address(newPool); // Permet la recherche dans les deux sens

        emit PoolCreated(_tokenA, _tokenB, address(newPool));
    }

    function getAllPools() external view returns (PoolInfo[] memory) {
        return pools;
    }
}
