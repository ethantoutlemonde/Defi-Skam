async function main() {
    // Obtenez les signataires de votre portefeuille (ici, un signataire local pour déploiement)
    const [owner, treasury] = await ethers.getSigners();
  
    console.log("Déploiement avec l'adresse du propriétaire : ", owner.address);
    console.log("Adresse de la trésorerie : ", treasury.address);
  
    // Déployer le contrat PoolToken (Token A et Token B)
    const TokenA = await ethers.getContractFactory("PoolToken");
    const TokenB = await ethers.getContractFactory("PoolToken");
  
    console.log("Déploiement des tokens...");
    const tokenA = await TokenA.deploy("Token A", "TKA");
    const tokenB = await TokenB.deploy("Token B", "TKB");
  
    // Attendez que les tokens soient déployés
    await tokenA.deployed();
    await tokenB.deployed();
  
    console.log("Token A déployé à :", tokenA.address);
    console.log("Token B déployé à :", tokenB.address);
  
    // Déployer le contrat LiquidityPool avec les adresses des tokens et la trésorerie
    const LiquidityPool = await ethers.getContractFactory("LiquidityPool");
  
    console.log("Déploiement du pool de liquidité...");
    const liquidityPool = await LiquidityPool.deploy(tokenA.address, tokenB.address, treasury.address);
  
    await liquidityPool.deployed();
  
    console.log("LiquidityPool déployé à :", liquidityPool.address);
  
    // Mint initial supply de Token A et Token B pour le propriétaire
    const mintAmount = ethers.utils.parseUnits("10000", 18);
    await tokenA.mint(owner.address, mintAmount);
    await tokenB.mint(owner.address, mintAmount);
  
    console.log(`10000 Token A et Token B envoyés à l'adresse ${owner.address}`);
  
    // Vous pouvez effectuer d'autres actions ici si nécessaire, comme initialiser des liquidités ou interagir avec le pool.
  }
  
  // Exécution de la fonction main() et gestion des erreurs
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  