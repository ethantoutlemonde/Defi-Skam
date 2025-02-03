const pool = await ethers.getContractAt("LiquidityPool", "ADRESSE_DU_POOL");

// Vérifier les réserves avant swap
const reserves = await pool.getReserves();
console.log(`Reserves Avant Swap - A: ${reserves[0].toString()}, B: ${reserves[1].toString()}`);

// Effectuer un swap avec frais de 2%
await pool.swap("0xAdresseTokenA", ethers.utils.parseEther("100"));

// Vérifier les nouvelles réserves et le ratio
const newReserves = await pool.getReserves();
console.log(`Reserves Après Swap - A: ${newReserves[0].toString()}, B: ${newReserves[1].toString()}`);

const newRatio = await pool.getLiquidityRatio();
console.log(`Nouveau Ratio: ${ethers.utils.formatUnits(newRatio, 18)}`);
