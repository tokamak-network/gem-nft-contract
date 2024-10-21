const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  
  // Fetch environment variables
  const gemFactoryAddress = process.env.GEM_FACTORY;
  const gemFactoryMiningAddress = process.env.GEM_FACTORY_MINING;
  const gemFactoryProxyAddress = process.env.GEM_FACTORY_PROXY;
  const marketPlaceAddress = process.env.MARKETPLACE;
  const treasuryAddress = process.env.TREASURY;
  const swapPool = process.env.WSTON_SWAP_POOL;
  const randomPackAddress = process.env.RANDOM_PACK;
  const drbCoordinatorAddress = process.env.DRB_COORDINATOR_MOCK;
  const owner = "0x15759359e60a3b9e59eA7A96D10Fa48829f83bEb"
  
  if (!gemFactoryAddress || !gemFactoryProxyAddress|| !marketPlaceAddress || !treasuryAddress || !randomPackAddress || !drbCoordinatorAddress) {
    throw new Error("Environment variables GEM_FACTORY, MARKETPLACE, TREASURY, RANDOM_PACK and DRB_COORDINATOR_MOCK must be set");
  }
  
  // Get contract instances
  const GemFactory = await ethers.getContractAt("GemFactory", gemFactoryAddress);
  const GemFactoryMining = await ethers.getContractAt("GemFactoryMining", gemFactoryMiningAddress);
  const MarketPlace = await ethers.getContractAt("MarketPlace", marketPlaceAddress);
  const Treasury = await ethers.getContractAt("Treasury", treasuryAddress);
  const RandomPack = await ethers.getContractAt("RandomPack", randomPackAddress)


  // ---------------------------- GEMFACTORY INITIALIZATION ---------------------------------
  // Attach the GemFactory interface to the GemFactoryProxy address
  const gemFactoryProxyAsGemFactory = GemFactory.attach(gemFactoryProxyAddress);
  /*
    // Initialize GemFactory with newly created contract addresses
    const initializeTx = await gemFactoryProxyAsGemFactory.initialize(
      owner,
      process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
      process.env.TON_ADDRESS, // l2ton
      treasuryAddress, // treasury
      { gasLimit: 10000000 }
  );
  await initializeTx.wait();
  console.log("GemFactory initialized");


  // Attach the GemFactoryMining interface to the GemFactoryProxy address
  const gemFactoryProxyAsGemFactoryMining = GemFactoryMining.attach(gemFactoryProxyAddress);

  // Initialize GemFactoryMining with DRB Coordinator Mock address
  const drbInitializeTx = await gemFactoryProxyAsGemFactoryMining.DRBInitialize(
    drbCoordinatorAddress
  );
  await drbInitializeTx.wait();
  console.log("GemFactoryMining DRB initialized");

  // ---------------------------- TREASURY INITIALIZATION ---------------------------------

  // Call the Treasury initialize function
  const tx2 = await Treasury.initialize(
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS, // l2ton
    gemFactoryAddress
  );
  await tx2.wait();
  console.log("Treasury initialized");

  // -------------------------- MARKETPLACE INITIALIZATION -------------------------------

  // Call the MarketPlace initialize function
  const tx3 = await MarketPlace.initialize(
    treasuryAddress,
    gemFactoryAddress,
    BigInt(10), // ton fee rate = 10
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS, // l2ton
  );
  await tx3.wait();
  console.log("MarketPlace initialized");

  // -------------------------- RANDOMPACK INITIALIZATION -------------------------------

  //initializing the randomPack contract
  const tx4 = await RandomPack.initialize(
    drbCoordinatorAddress,
    process.env.TON_ADDRESS, // l2ton
    gemFactoryAddress,
    treasuryAddress,
    BigInt(15), // ton fee prices = 10
  );
  await tx4.wait();
  console.log("RandomPack initialized");

  // -------------------------------- STORAGE SETTER ----------------------------------

  await gemFactoryProxyAsGemFactory.setGemsValue(
    BigInt(10) ** BigInt(27) * BigInt(10), // commonGemsValue
    BigInt(10) ** BigInt(27) * BigInt(19), // rareGemsValue
    BigInt(10) ** BigInt(27) * BigInt(54), // uniqueGemsValue
    BigInt(10) ** BigInt(27) * BigInt(205), // epicGemsValue
    BigInt(10) ** BigInt(27) * BigInt(974), // legendaryGemsValue
    BigInt(10) ** BigInt(27) * BigInt(5552), // mythicGemsValue
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
  await gemFactoryProxyAsGemFactory.setMarketPlaceAddress(marketPlaceAddress);
  console.log("MarketPlace address set in GemFactory");

  await Treasury.setMarketPlace(marketPlaceAddress);
  console.log("MarketPlace address set in Treasury");


  await Treasury.setWstonSwapPool(swapPool);
  console.log("Swap pool address set in Treasury");

  await Treasury.setRandomPack(randomPackAddress);
  console.log("Random pack address set in Treasury");

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

  */

  await RandomPack.setGemFactory(gemFactoryAddress);
  console.log("gemFactory set in RandomPack")

  await RandomPack.setTreasury(treasuryAddress);
  console.log("Treasury set in RandomPack")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
