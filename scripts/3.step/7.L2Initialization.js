const { ethers } = require("hardhat");
require('dotenv').config();
// command to run: "source .env"
// command to run: "npx hardhat run scripts/3.step/7.L2Initialization.js --network titan"

async function main() {
  const [deployer] = await ethers.getSigners();

  
  // Fetch environment variables
  const gemFactoryAddress = process.env.GEM_FACTORY;
  const gemFactoryMiningAddress = process.env.GEM_FACTORY_MINING;
  const gemFactoryProxyAddress = process.env.GEM_FACTORY_PROXY;
  const marketPlaceAddress = process.env.MARKETPLACE;
  const marketPlaceProxyAddress = process.env.MARKETPLACE_PROXY;
  const treasuryAddress = process.env.TREASURY;
  const treasuryProxyAddress = process.env.TREASURY_PROXY;
  const swapPoolAddress = process.env.WSTON_SWAP_POOL;
  const swapPoolProxyAddress = process.env.WSTON_SWAP_POOL_PROXY;
  const randomPackAddress = process.env.RANDOM_PACK;
  const randomPackProxyAddress = process.env.RANDOM_PACK_PROXY;
  const drbCoordinatorAddress = process.env.DRB_COORDINATOR_MOCK;
  const owner = "0x5c5c36Bb1e3B266637F6830FCAe2Ee2715339Eb1"
  
  if (!gemFactoryAddress || !gemFactoryProxyAddress|| !marketPlaceAddress || !treasuryAddress || !randomPackAddress || !drbCoordinatorAddress) {
    throw new Error("Environment variables GEM_FACTORY, MARKETPLACE, TREASURY, RANDOM_PACK and DRB_COORDINATOR_MOCK must be set");
  }
  
  // Get contract instances
  const GemFactory = await ethers.getContractAt("GemFactory", gemFactoryAddress);
  const GemFactoryMining = await ethers.getContractAt("GemFactoryMining", gemFactoryMiningAddress);
  const MarketPlace = await ethers.getContractAt("MarketPlace", marketPlaceAddress);
  const Treasury = await ethers.getContractAt("Treasury", treasuryAddress);
  const RandomPack = await ethers.getContractAt("RandomPack", randomPackAddress);
  const WstonSwapPool = await ethers.getContractAt("WstonSwapPool", swapPoolAddress);

  // ---------------------------- GEMFACTORYPROXY INITIALIZATION ---------------------------------
  // Attach the GemFactory interface to the GemFactoryProxy address
  const gemFactoryProxyAsGemFactory = GemFactory.attach(gemFactoryProxyAddress);

  // Initialize GemFactory with newly created contract addresses
  const initializeTx = await gemFactoryProxyAsGemFactory.initialize(
    owner,
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS, // l2ton
    treasuryProxyAddress, // treasury
    { gasLimit: 10000000 }
  );
  await initializeTx.wait();
  console.log("GemFactoryProxy initialized");


  // Attach the GemFactoryMining interface to the GemFactoryProxy address
  const gemFactoryProxyAsGemFactoryMining = GemFactoryMining.attach(gemFactoryProxyAddress);

  // Initialize GemFactoryMining with DRB Coordinator Mock address
  const drbInitializeTx = await gemFactoryProxyAsGemFactoryMining.DRBInitialize(
    drbCoordinatorAddress
  );
  await drbInitializeTx.wait();
  console.log("GemFactoryMining DRB initialized");

  // ---------------------------- TREASURYPROXY INITIALIZATION ---------------------------------
  // Attach the Treasury interface to the TreasuryProxy contract address
  const treasuryProxyAsTreasury = Treasury.attach(treasuryProxyAddress);
  // Call the Treasury initialize function
  const tx2 = await treasuryProxyAsTreasury.initialize(
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS, // l2ton
    gemFactoryProxyAddress
  );
  await tx2.wait();
  console.log("TreasuryProxy initialized");

  // -------------------------- MARKETPLACEPROXY INITIALIZATION -------------------------------

  // Attach the MarketPlace interface to the MarketPlaceProxy contract address
  const marketPlaceProxyAsMarketPlace = MarketPlace.attach(marketPlaceProxyAddress);

  // Call the MarketPlace initialize function
  const tx3 = await marketPlaceProxyAsMarketPlace.initialize(
    treasuryProxyAddress,
    gemFactoryProxyAddress,
    BigInt(10), // ton fee rate = 10
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS, // l2ton
  );
  await tx3.wait();
  console.log("MarketPlaceProxy initialized");

  // -------------------------- RANDOMPACKPROXY INITIALIZATION -------------------------------

  // Attach the RandomPack interface to the RandomPackProxy contract address
  const randomPackProxyAsRandomPack = RandomPack.attach(randomPackProxyAddress);

  //initializing the randomPack contract
  const tx4 = await randomPackProxyAsRandomPack.initialize(
    drbCoordinatorAddress,
    process.env.TON_ADDRESS, // l2ton
    gemFactoryProxyAddress,
    treasuryProxyAddress,
    BigInt(15000000000000000000), 
  );
  await tx4.wait();
  console.log("RandomPackProxy initialized");

  // -------------------------- WSTONSWAPPOOLPROXY INITIALIZATION -------------------------------

  // Attach the RandomPack interface to the RandomPackProxy contract address
  const wstonSwapPoolProxyAsWstonSwapPool = WstonSwapPool.attach(swapPoolProxyAddress);

  //initializing the randomPack contract
  const tx5 = await wstonSwapPoolProxyAsWstonSwapPool.initialize(
    process.env.TON_ADDRESS, // l2ton
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    BigInt(1) ** BigInt(27), // staking index = 1e27
    treasuryProxyAddress
  );
  await tx5.wait();
  console.log("WstonSwapPoolProxy initialized");

  // -------------------------------- STORAGE SETTER ----------------------------------


  await gemFactoryProxyAsGemFactory.setGemsValue(
    BigInt(10) ** BigInt(27) * BigInt(10), // commonGemsValue
    BigInt(10) ** BigInt(27) * BigInt(19), // rareGemsValue
    BigInt(10) ** BigInt(27) * BigInt(55), // uniqueGemsValue
    BigInt(10) ** BigInt(27) * BigInt(214), // epicGemsValue
    BigInt(10) ** BigInt(27) * BigInt(1040), // legendaryGemsValue
    BigInt(10) ** BigInt(27) * BigInt(6060), // mythicGemsValue
    {gasLimit: 1000000}
  );
  console.log("gem values set");

  await gemFactoryProxyAsGemFactory.setGemsMiningPeriods(
    BigInt(10 * 60), // RareGemsMiningPeriod (10 min)
    BigInt(10 * 60), // UniqueGemsMiningPeriod (10 min)
    BigInt(10 * 60), // EpicGemsMiningPeriod (10 min)
    BigInt(10 * 60), // LegendaryGemsMiningPeriod (10 min)
    BigInt(10 * 60),  // MythicGemsMiningPeriod (10 min)
    {gasLimit: 1000000}
  );
  console.log("Gems Mining Periods set");

  // Set Gems Cooldown Periods
  await gemFactoryProxyAsGemFactory.setGemsCooldownPeriods(
    BigInt(1 * 7 * 24 * 60 * 60), // RareGemsCooldownPeriod (1 weeks)
    BigInt(3 * 24 * 60 * 60), // UniqueGemsCooldownPeriod (3 days)
    BigInt(24 * 60 * 60), // EpicGemsCooldownPeriod (24 hours)
    BigInt(12 * 60 * 60), // LegendaryGemsCooldownPeriod (12 hours)
    BigInt(4 * 60 * 60),  // MythicGemsCooldownPeriod (4 hours)
    {gasLimit: 1000000}
  );
  console.log("Gems Cooldown Periods set");

  // Set Mining Trys
  await gemFactoryProxyAsGemFactory.setMiningTries(
    BigInt(1),  // rareminingTry
    BigInt(2),  // uniqueminingTry
    BigInt(4), // epicminingTry
    BigInt(8), // legendaryminingTry
    BigInt(16),  // mythicminingTry
    {gasLimit: 1000000}
  );
  console.log("Mining Trys set");
  
  // Set MarketPlace Address in GemFactory
  const setMarketPlaceAddressinGemFactory = await gemFactoryProxyAsGemFactory.setMarketPlaceAddress(marketPlaceProxyAddress);
  setMarketPlaceAddressinGemFactory.wait();
  console.log("MarketPlaceProxy address set in GemFactoryProxy");

  await treasuryProxyAsTreasury.setMarketPlace(marketPlaceProxyAddress);
  console.log("MarketPlaceProxy address set in Treasury");


  await treasuryProxyAsTreasury.setWstonSwapPool(swapPoolProxyAddress);
  console.log("WstonSwapPoolProxy address set in TreasuryProxy");

  await treasuryProxyAsTreasury.setRandomPack(randomPackProxyAddress);
  console.log("RandomPackProxy address set in TreasuryProxy");

  // we set up the list of colors available for the GEM
  await gemFactoryProxyAsGemFactory.addColor("Ruby",0,0);
  await gemFactoryProxyAsGemFactory.addColor("Ruby/Amber",0,1);
  await gemFactoryProxyAsGemFactory.addColor("Amber",1,1);
  await gemFactoryProxyAsGemFactory.addColor("Topaz",2,2);
  await gemFactoryProxyAsGemFactory.addColor("Topaz/Emerald",2,3);
  await gemFactoryProxyAsGemFactory.addColor("Emerald/Topaz",3,2);
  await gemFactoryProxyAsGemFactory.addColor("Emerald",3,3);
  await gemFactoryProxyAsGemFactory.addColor("Emerald/Amber",3,1);
  await gemFactoryProxyAsGemFactory.addColor("Turquoise",4,4);
  await gemFactoryProxyAsGemFactory.addColor("Sapphire",5,5);
  await gemFactoryProxyAsGemFactory.addColor("Amethyst",6,6);
  await gemFactoryProxyAsGemFactory.addColor("Amethyst/Amber",6,1);
  await gemFactoryProxyAsGemFactory.addColor("Garnet",7,7);

  await randomPackProxyAsRandomPack.setGemFactory(gemFactoryProxyAddress);
  console.log("GemFactoryProxy set in RandomPackProxy")
  
  await randomPackProxyAsRandomPack.setTreasury(treasuryProxyAddress);
  console.log("TreasuryProxy set in RandomPackProxy")

  await randomPackProxyAsRandomPack.setProbabilities(50,30,20,0,0,0);
  console.log("probabilities set in RandomPackProxy")

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
