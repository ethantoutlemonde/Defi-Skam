const { expect, anyValue } = require("@nomicfoundation/hardhat-chai-matchers");
const { ethers } = require("hardhat");

describe("LiquidityPool", function () {
    let LiquidityPool, liquidityPool, TokenA, TokenB, tokenA, tokenB, owner, addr1, addr2, treasury;

    beforeEach(async function () {
        console.log("Début du beforeEach...");
    
        [owner, addr1, addr2, treasury] = await ethers.getSigners();
        
        TokenA = await ethers.getContractFactory("PoolToken");
        TokenB = await ethers.getContractFactory("PoolToken");
        
        tokenA = await TokenA.deploy("Token A", "TKA");
        tokenB = await TokenB.deploy("Token B", "TKB");
        await tokenA.waitForDeployment();
        await tokenB.waitForDeployment();
        
        LiquidityPool = await ethers.getContractFactory("LiquidityPool");
        liquidityPool = await LiquidityPool.deploy(tokenA.target, tokenB.target, treasury.address);
        await liquidityPool.waitForDeployment();
        
        // Mint initial supply to owner
        await tokenA.mint(owner.address, 10000);
        await tokenB.mint(owner.address, 10000);
        
        console.log("Fin du beforeEach...");
    });

    it("Devrait ajouter des liquidités et émettre des LP tokens", async function () {
        await tokenA.transfer(addr1.address, 1000);
        await tokenB.transfer(addr1.address, 1000);
        
        await tokenA.connect(addr1).approve(liquidityPool.target, 1000);
        await tokenB.connect(addr1).approve(liquidityPool.target, 1000);
        
        await expect(liquidityPool.connect(addr1).addLiquidity(500, 500))
            .to.emit(liquidityPool, "LiquidityAdded")
            .withArgs(addr1.address, anyValue, anyValue, anyValue);
    });

    it("Devrait permettre de retirer des liquidités", async function () {
        await tokenA.transfer(addr1.address, 1000);
        await tokenB.transfer(addr1.address, 1000);
        await tokenA.connect(addr1).approve(liquidityPool.target, 1000);
        await tokenB.connect(addr1).approve(liquidityPool.target, 1000);
        
        await liquidityPool.connect(addr1).addLiquidity(500, 500);
        const lpBalance = await liquidityPool.lpToken().balanceOf(addr1.address);
        
        await expect(liquidityPool.connect(addr1).removeLiquidity(lpBalance))
            .to.emit(liquidityPool, "LiquidityRemoved")
            .withArgs(addr1.address, anyValue, anyValue, anyValue, anyValue);
    });

    it("Devrait exécuter un swap et collecter des frais", async function () {
        await tokenA.transfer(addr1.address, 1000);
        await tokenB.transfer(addr1.address, 1000);
        await tokenA.connect(addr1).approve(liquidityPool.target, 1000);
        await tokenB.connect(addr1).approve(liquidityPool.target, 1000);
        
        await liquidityPool.connect(addr1).addLiquidity(500, 500);
        
        await tokenA.connect(addr1).approve(liquidityPool.target, 500);
        await expect(liquidityPool.connect(addr1).swap(tokenA.target, 100))
            .to.emit(liquidityPool, "SwapExecuted")
            .withArgs(addr1.address, anyValue, anyValue, tokenA.target, tokenB.target, anyValue);
    });
});
