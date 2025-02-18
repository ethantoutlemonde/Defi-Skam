// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply, address _owner) 
        ERC20(_name, _symbol) 
    {
        _mint(_owner, _initialSupply * 10**decimals());
    }
}

contract TokenFactory is Ownable {
    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        uint256 totalSupply;
    }

    TokenInfo[] public tokens;
    mapping(address => TokenInfo) public tokenByAddress;

    event TokenCreated(address indexed creator, address tokenAddress, string name, string symbol, uint256 totalSupply);

    constructor() Ownable(msg.sender) {}

    function createToken(string memory _name, string memory _symbol, uint256 _initialSupply) external {
        CustomERC20 newToken = new CustomERC20(_name, _symbol, _initialSupply, msg.sender);
        TokenInfo memory newTokenInfo = TokenInfo(
            address(newToken),
            _name,
            _symbol,
            _initialSupply
        );

        tokens.push(newTokenInfo);
        tokenByAddress[address(newToken)] = newTokenInfo;

        emit TokenCreated(msg.sender, address(newToken), _name, _symbol, _initialSupply);
    }

    function getAllTokens() external view returns (TokenInfo[] memory) {
        return tokens;
    }

    function getTokenInfo(address tokenAddress) external view returns (TokenInfo memory) {
        return tokenByAddress[tokenAddress];
    }
}


//ok tier