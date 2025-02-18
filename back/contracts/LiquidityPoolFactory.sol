// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LiquidityPool.sol";
import "./ErrorLibrary.sol";

contract LiquidityPoolFactory {
    event PoolCreated(address indexed poolAddress, address tokenA, address tokenB, address treasury);

    mapping(address => mapping(address => address)) public getPool;
    address[] public allPools;

    function createPool(
        address tokenA, 
        address tokenB, 
        address treasury, 
        address priceFeedA, 
        address priceFeedB
    ) external returns (address) {
        require(tokenA != tokenB, ErrorLibrary.TOKENS_MUST_BE_DIFFERENT());
        require(getPool[tokenA][tokenB] == address(0), ErrorLibrary.POOL_ALREADY_EXISTS(address(getPool[tokenA][tokenB])));

        LiquidityPool pool = new LiquidityPool(tokenA, tokenB, treasury, priceFeedA, priceFeedB);
        address poolAddress = address(pool);

        getPool[tokenA][tokenB] = poolAddress;
        getPool[tokenB][tokenA] = poolAddress;
        allPools.push(poolAddress);

        emit PoolCreated(poolAddress, tokenA, tokenB, treasury);
        return poolAddress;
    }

    function getAllPools() external view returns (address[] memory) {
        return allPools;
    }
}
