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

  const swapPoolProxyAddress = process.env.WSTON_SWAP_POOL_PROXY;
  const randomPackAddress = process.env.RANDOM_PACK;
  const randomPackProxyAddress = process.env.RANDOM_PACK_PROXY;
  const drbCoordinatorAddress = process.env.DRB_COORDINATOR_MOCK;
  const owner = "0x5c5c36Bb1e3B266637F6830FCAe2Ee2715339Eb1"
  
  if (!gemFactoryAddress || !gemFactoryProxyAddress|| !marketPlaceAddress || !treasuryAddress || !randomPackAddress || !drbCoordinatorAddress) {
    throw new Error("Environment variables GEM_FACTORY, MARKETPLACE, TREASURY, RANDOM_PACK and DRB_COORDINATOR_MOCK must be set");
  }
  
  // Get contract instances
  const GemFactory = await ethers.getContractAt("GemFactory", gemFactoryProxyAddress);
  const GemFactoryMining = await ethers.getContractAt("GemFactoryMining", gemFactoryMiningAddress);
  const MarketPlace = await ethers.getContractAt("MarketPlaceThanos", marketPlaceProxyAddress);
  const Treasury = await ethers.getContractAt("TreasuryThanos", treasuryProxyAddress);
  const RandomPack = await ethers.getContractAt("RandomPackThanos", randomPackProxyAddress);
  const WstonSwapPool = await ethers.getContractAt("WstonSwapPoolThanos", swapPoolProxyAddress);

  // ---------------------------- GEMFACTORYPROXY INITIALIZATION ---------------------------------

  // Initialize GemFactory with newly created contract addresses
  const initializeTx = await GemFactory.initialize(
    owner,
    process.env.THANOS_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS, // l2ton
    treasuryProxyAddress, // treasury
    { gasLimit: 10000000 }
  );
  await initializeTx.wait();
  console.log("GemFactoryProxy initialized");

  // Initialize GemFactoryMining with DRB Coordinator Mock address
  const drbInitializeTx = await GemFactoryMining.DRBInitialize(
    drbCoordinatorAddress
  );
  await drbInitializeTx.wait();
  console.log("GemFactoryMining DRB initialized");

  // ---------------------------- TREASURYPROXY INITIALIZATION ---------------------------------
  // Attach the Treasury interface to the TreasuryProxy contract address
  console.log("treasury initialization...");
  // Call the Treasury initialize function
  const tx2 = await Treasury.initialize(
    process.env.THANOS_WRAPPED_STAKED_TON, // l2wston
    gemFactoryProxyAddress
  );
  await tx2.wait();
  console.log("TreasuryProxy initialized");

  // -------------------------- MARKETPLACEPROXY INITIALIZATION -------------------------------


  // Call the MarketPlace initialize function
  const tx3 = await MarketPlace.initialize(
    treasuryProxyAddress,
    gemFactoryProxyAddress,
    BigInt(10), // ton fee rate = 10
    process.env.THANOS_WRAPPED_STAKED_TON, // l2wston
  );
  await tx3.wait();
  console.log("MarketPlaceProxy initialized");

  // -------------------------- RANDOMPACKPROXY INITIALIZATION -------------------------------

  //initializing the randomPack contract
  const tx4 = await RandomPack.initialize(
    drbCoordinatorAddress,
    gemFactoryProxyAddress,
    treasuryProxyAddress,
    BigInt(15000000000000000000), 
  );
  await tx4.wait();
  console.log("RandomPackProxy initialized");

  // -------------------------- WSTONSWAPPOOLPROXY INITIALIZATION -------------------------------

  //initializing the randomPack contract
  const tx5 = await WstonSwapPool.initialize(
    process.env.THANOS_WRAPPED_STAKED_TON, // l2wston
    BigInt(1) ** BigInt(27), // staking index = 1e27
    treasuryProxyAddress
  );
  await tx5.wait();
  console.log("WstonSwapPoolProxy initialized");

  // -------------------------------- STORAGE SETTER ----------------------------------


  await GemFactory.setGemsValue(
    BigInt(10) ** BigInt(27) * BigInt(10), // commonGemsValue
    BigInt(10) ** BigInt(27) * BigInt(19), // rareGemsValue
    BigInt(10) ** BigInt(27) * BigInt(55), // uniqueGemsValue
    BigInt(10) ** BigInt(27) * BigInt(214), // epicGemsValue
    BigInt(10) ** BigInt(27) * BigInt(1040), // legendaryGemsValue
    BigInt(10) ** BigInt(27) * BigInt(6060), // mythicGemsValue
    {gasLimit: 1000000}
  );
  console.log("gem values set");

  await GemFactory.setGemsMiningPeriods(
    BigInt(10 * 60), // RareGemsMiningPeriod (10 min)
    BigInt(10 * 60), // UniqueGemsMiningPeriod (10 min)
    BigInt(10 * 60), // EpicGemsMiningPeriod (10 min)
    BigInt(10 * 60), // LegendaryGemsMiningPeriod (10 min)
    BigInt(10 * 60),  // MythicGemsMiningPeriod (10 min)
    {gasLimit: 1000000}
  );
  console.log("Gems Mining Periods set");

  // Set Gems Cooldown Periods
  await GemFactory.setGemsCooldownPeriods(
    BigInt(1 * 7 * 24 * 60 * 60), // RareGemsCooldownPeriod (1 weeks)
    BigInt(3 * 24 * 60 * 60), // UniqueGemsCooldownPeriod (3 days)
    BigInt(24 * 60 * 60), // EpicGemsCooldownPeriod (24 hours)
    BigInt(12 * 60 * 60), // LegendaryGemsCooldownPeriod (12 hours)
    BigInt(4 * 60 * 60),  // MythicGemsCooldownPeriod (4 hours)
    {gasLimit: 1000000}
  );
  console.log("Gems Cooldown Periods set");

  // Set Mining Trys
  await GemFactory.setMiningTries(
    BigInt(1),  // rareminingTry
    BigInt(2),  // uniqueminingTry
    BigInt(4), // epicminingTry
    BigInt(8), // legendaryminingTry
    BigInt(16),  // mythicminingTry
    {gasLimit: 1000000}
  );
  console.log("Mining Trys set");

  // Set MarketPlace Address in GemFactory
  const setMarketPlaceAddressinGemFactory = await GemFactory.setMarketPlaceAddress(marketPlaceProxyAddress);
  setMarketPlaceAddressinGemFactory.wait();
  console.log("MarketPlaceProxy address set in GemFactoryProxy");

  await Treasury.setMarketPlace(marketPlaceProxyAddress);
  console.log("MarketPlaceProxy address set in Treasury");


  await Treasury.setWstonSwapPool(swapPoolProxyAddress);
  console.log("WstonSwapPoolProxy address set in TreasuryProxy");

  await Treasury.setRandomPack(randomPackProxyAddress);
  console.log("RandomPackProxy address set in TreasuryProxy");

  // we set up the list of colors available for the GEM
  await GemFactory.addColor("Ruby",0,0);
  await GemFactory.addColor("Ruby/Amber",0,1);
  await GemFactory.addColor("Ruby/Topaz",0,2);
  await GemFactory.addColor("Ruby/Emerald",0,3);
  await GemFactory.addColor("Ruby/Turquoise",0,4);
  await GemFactory.addColor("Ruby/Sapphire",0,5);
  await GemFactory.addColor("Ruby/Amethyst",0,6);
  await GemFactory.addColor("Ruby/Garnet",0,7);

  await GemFactory.addColor("Amber/Ruby",1,0);
  await GemFactory.addColor("Amber",1,1);
  await GemFactory.addColor("Amber/Topaz",1,2);
  await GemFactory.addColor("Amber/Emerald",1,3);
  await GemFactory.addColor("Amber/Turquoise",1,4);
  await GemFactory.addColor("Amber/Sapphire",1,5);
  await GemFactory.addColor("Amber/Amethyst",1,6);
  await GemFactory.addColor("Amber/Garnet",1,7);

  await GemFactory.addColor("Topaz/Ruby",2,0);
  await GemFactory.addColor("Topaz/Amber",2,1);
  await GemFactory.addColor("Topaz",2,2);
  await GemFactory.addColor("Topaz/Emerald",2,3);
  await GemFactory.addColor("Topaz/Turquoise",2,4);
  await GemFactory.addColor("Topaz/Sapphire",2,5);
  await GemFactory.addColor("Topaz/Amethyst",2,6);
  await GemFactory.addColor("Topaz/Garnet",2,7);

  await GemFactory.addColor("Emerald/Ruby",3,0);
  await GemFactory.addColor("Emerald/Amber",3,1);
  await GemFactory.addColor("Emerald/Topaz",3,2);
  await GemFactory.addColor("Emerald",3,3);
  await GemFactory.addColor("Emerald/Turquoise",3,4);
  await GemFactory.addColor("Emerald/Sapphire",3,5);
  await GemFactory.addColor("Emerald/Amethyst",3,6);
  await GemFactory.addColor("Emerald/Garnet",3,7);

  await GemFactory.addColor("Turquoise/Ruby",4,0);
  await GemFactory.addColor("Turquoise/Amber",4,1);
  await GemFactory.addColor("Turquoise/Topaz",4,2);
  await GemFactory.addColor("Turquoise/Emerald",4,3);
  await GemFactory.addColor("Turquoise",4,4);
  await GemFactory.addColor("Turquoise/Sapphire",4,5);
  await GemFactory.addColor("Turquoise/Amethyst",4,6);
  await GemFactory.addColor("Turquoise/Garnet",4,7);

  await GemFactory.addColor("Sapphire/Ruby",5,0);
  await GemFactory.addColor("Sapphire/Amber",5,1);
  await GemFactory.addColor("Sapphire/Topaz",5,2);
  await GemFactory.addColor("Sapphire/Emerald",5,3);
  await GemFactory.addColor("Sapphire/Turquoise",5,4);
  await GemFactory.addColor("Sapphire",5,5);
  await GemFactory.addColor("Sapphire/Amethyst",5,6);
  await GemFactory.addColor("Sapphire/Garnet",5,7);

  await GemFactory.addColor("Amethyst/Ruby",6,0);
  await GemFactory.addColor("Amethyst/Amber",6,1);
  await GemFactory.addColor("Amethyst/Topaz",6,2);
  await GemFactory.addColor("Amethyst/Emerald",6,3);
  await GemFactory.addColor("Amethyst/Turquoise",6,4);
  await GemFactory.addColor("Amethyst/Sapphire",6,5);
  await GemFactory.addColor("Amethyst",6,6);
  await GemFactory.addColor("Amethyst/Garnet",6,7);

  await GemFactory.addColor("Garnet/Ruby",7,0);
  await GemFactory.addColor("Garnet/Amber",7,1);
  await GemFactory.addColor("Garnet/Topaz",7,2);
  await GemFactory.addColor("Garnet/Emerald",7,3);
  await GemFactory.addColor("Garnet/Turquoise",7,4);
  await GemFactory.addColor("Garnet/Sapphire",7,5);
  await GemFactory.addColor("Garnet/Amethyst",7,6);
  await GemFactory.addColor("Garnet",7,7);
  console.log("colors initialized in GemFactoryProxy")

  await RandomPack.setGemFactory(gemFactoryProxyAddress);
  console.log("GemFactoryProxy set in RandomPackProxy")
  
  await RandomPack.setTreasury(treasuryProxyAddress);
  console.log("TreasuryProxy set in RandomPackProxy")

  await RandomPack.setProbabilities(50,30,20,0,0,0);
  console.log("probabilities set in RandomPackProxy")

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
