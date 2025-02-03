const pool = await ethers.getContractAt("LiquidityPool", "ADRESSE_POOL");

// Vérifier les réserves avant
const reserves = await pool.getReserves();
console.log(`Reserves Avant - A: ${reserves[0].toString()}, B: ${reserves[1].toString()}`);

// Ajouter de la liquidité
await pool.addLiquidity(ethers.utils.parseEther("100"), ethers.utils.parseEther("100"));

// Vérifier le solde des LP Tokens
const lpToken = await ethers.getContractAt("PoolToken", await pool.lpToken());
const lpBalance = await lpToken.balanceOf("0xAdresseUser");
console.log(`LP Tokens détenus: ${ethers.utils.formatUnits(lpBalance, 18)}`);

// Swap avec frais de 2%
await pool.swap("0xAdresseTokenA", ethers.utils.parseEther("50"));

// Vérifier les réserves après le swap
const newReserves = await pool.getReserves();
console.log(`Reserves Après - A: ${newReserves[0].toString()}, B: ${newReserves[1].toString()}`);
