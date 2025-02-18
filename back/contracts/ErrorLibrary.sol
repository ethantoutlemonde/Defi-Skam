// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ErrorLibrary {
    // General errors
    error TOKENS_MUST_BE_DIFFERENT();
    error POOL_ALREADY_EXISTS(address poolAddress);
    error UNAUTHORIZED();

    // Errors related to the liquidity pool
    error AMOUNTS_MUST_BE_GREATER_THAN_ZERO();
    error LP_AMOUNT_MUST_BE_GREATER_THAN_ZERO();
    error INSUFFICIENT_LP_BALANCE();
    error INVALID_POOL();

    // Errors related to the swap
    error INVALID_TOKEN();
    error AMOUNT_MUST_BE_GREATER_THAN_ZERO();
    error INVALID_RESERVES();
    error SWAP_AMOUNT_TOO_LOW();
    error PRICE_SLIPPAGE_TOO_HIGH();

    // Other errors
    error DIVISION_BY_ZERO();

    // TokenErrors
    error ONLY_POOL_CAN_BURN_OR_MINT();
}
