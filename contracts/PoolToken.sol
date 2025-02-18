// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ErrorLibrary.sol";

contract PoolToken is ERC20 {
    address public poolContract;

    modifier onlyPool() {
        require(msg.sender == poolContract, ErrorLibrary.ONLY_POOL_CAN_BURN_OR_MINT());
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        poolContract = msg.sender;
    }

    function mint(address to, uint256 amount) external onlyPool {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyPool {
        _burn(from, amount);
    }
}


//ok tier