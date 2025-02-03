const pool = await ethers.getContractAt("LiquidityPool", "ADRESSE_DU_POOL");

// Voir les réserves initiales
const reserves = await pool.getReserves();
console.log(`Reserves A: ${reserves[0].toString()}, Reserves B: ${reserves[1].toString()}`);

// Voir le ratio actuel
const ratio = await pool.getLiquidityRatio();
console.log(`Ratio: ${ethers.utils.formatUnits(ratio, 18)}`);

// Effectuer un swap
await pool.swap("0xAdresseTokenA", ethers.utils.parseEther("100"));

// Vérifier le nouveau ratio
const newRatio = await pool.getLiquidityRatio();
console.log(`Nouveau Ratio: ${ethers.utils.formatUnits(newRatio, 18)}`);
