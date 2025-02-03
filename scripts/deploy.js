const hre = require("hardhat");

async function main() {
    // Déploiement de la PoolFactory
    const PoolFactory = await hre.ethers.getContractFactory("PoolFactory");
    const poolFactory = await PoolFactory.deploy();

    await poolFactory.deployed();
    console.log(`PoolFactory déployée à l'adresse: ${poolFactory.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
