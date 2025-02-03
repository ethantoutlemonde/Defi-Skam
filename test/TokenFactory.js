const factory = await ethers.getContractAt("PoolFactory", "ADRESSE_DEPLOIEMENT");

// Remplace par les adresses de tes tokens ERC20
const tokenA = "0xAdresseTokenA";
const tokenB = "0xAdresseTokenB";

// Ajoute de la liquidité initiale
await factory.createPool(tokenA, tokenB, ethers.utils.parseEther("1000"), ethers.utils.parseEther("1000"));
