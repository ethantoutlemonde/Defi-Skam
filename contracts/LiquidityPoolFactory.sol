// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LiquidityPool.sol";

contract LiquidityPoolFactory {
    event PoolCreated(address indexed poolAddress, address tokenA, address tokenB);

    mapping(address => mapping(address => address)) public getPool;
    address[] public allPools;

    function createPool(address tokenA, address tokenB) external returns (address) {
        require(tokenA != tokenB, "Tokens must be different");
        require(getPool[tokenA][tokenB] == address(0), "Pool already exists");

        LiquidityPool pool = new LiquidityPool(tokenA, tokenB);
        address poolAddress = address(pool);

        getPool[tokenA][tokenB] = poolAddress;
        getPool[tokenB][tokenA] = poolAddress; // Support bidirectional lookup
        allPools.push(poolAddress);

        emit PoolCreated(poolAddress, tokenA, tokenB);
        return poolAddress;
    }

    function getAllPools() external view returns (address[] memory) {
        return allPools;
    }
}