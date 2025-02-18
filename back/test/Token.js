const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TokenFactory", function () {
  let owner;
  let addr1;
  let TokenFactory;
  let tokenFactory;
  let CustomERC20;
  let newToken;
  let initialSupply = 1000;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    // Déploiement de TokenFactory
    TokenFactory = await ethers.getContractFactory("TokenFactory");
    tokenFactory = await TokenFactory.deploy();
    await tokenFactory.deployed();

    // Déploiement de CustomERC20 pour tester sa création
    CustomERC20 = await ethers.getContractFactory("CustomERC20");
  });

  it("should deploy TokenFactory contract", async function () {
    expect(tokenFactory.address).to.be.properAddress;
  });

  it("should create a new token via TokenFactory", async function () {
    // Création du token
    await tokenFactory.createToken("MyToken", "MTK", initialSupply);

    // Vérification des événements
    await expect(tokenFactory.createToken("NewToken", "NTK", initialSupply))
      .to.emit(tokenFactory, "TokenCreated")
      .withArgs(owner.address, ethers.constants.AddressZero, "NewToken", "NTK", initialSupply);

    // Récupération des informations du token
    const allTokens = await tokenFactory.getAllTokens();
    expect(allTokens.length).to.equal(1);

    const tokenInfo = allTokens[0];
    expect(tokenInfo.name).to.equal("MyToken");
    expect(tokenInfo.symbol).to.equal("MTK");
    expect(tokenInfo.totalSupply.toString()).to.equal(initialSupply.toString());

    // Vérification de la création du token ERC20
    newToken = CustomERC20.attach(tokenInfo.tokenAddress);
    const name = await newToken.name();
    const symbol = await newToken.symbol();
    const totalSupply = await newToken.totalSupply();

    expect(name).to.equal("MyToken");
    expect(symbol).to.equal("MTK");
    expect(totalSupply.toString()).to.equal((initialSupply * 10 ** 18).toString()); // considering decimals
  });

  it("should get token info by address", async function () {
    await tokenFactory.createToken("AnotherToken", "ATK", initialSupply);
    const allTokens = await tokenFactory.getAllTokens();
    const tokenAddress = allTokens[1].tokenAddress;

    const tokenInfo = await tokenFactory.getTokenInfo(tokenAddress);
    expect(tokenInfo.name).to.equal("AnotherToken");
    expect(tokenInfo.symbol).to.equal("ATK");
    expect(tokenInfo.totalSupply.toString()).to.equal(initialSupply.toString());
  });

  it("should only allow the owner to create tokens", async function () {
    await expect(
      tokenFactory.connect(addr1).createToken("RestrictedToken", "RTK", initialSupply)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });
});
