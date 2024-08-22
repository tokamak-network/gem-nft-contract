const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Initializing GemFactory with the account:", deployer.address);

  // Fetch environment variables
  const gemFactoryAddress = process.env.GEM_FACTORY;
  const marketPlaceAddress = process.env.MARKETPLACE;
  const treasuryAddress = process.env.TREASURY;

  if (!gemFactoryAddress || !marketPlaceAddress || !treasuryAddress) {
    throw new Error("Environment variables GEM_FACTORY, MARKETPLACE, and TREASURY must be set");
  }

  // Get contract instances
  const GemFactory = await ethers.getContractAt("GemFactory", gemFactoryAddress);
  const MarketPlace = await ethers.getContractAt("MarketPlace", marketPlaceAddress);
  const Treasury = await ethers.getContractAt("Treasury", treasuryAddress);

  // Call the initialize function
  const tx = await GemFactory.initialize(
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS, // l2ton
    treasuryAddress, // treasury
    BigInt(10) ** BigInt(27) * BigInt(10), // commonGemsValue
    BigInt(10) ** BigInt(27) * BigInt(19), // rareGemsValue
    BigInt(10) ** BigInt(27) * BigInt(53), // uniqueGemsValue
    BigInt(10) ** BigInt(27) * BigInt(204), // epicGemsValue
    BigInt(10) ** BigInt(27) * BigInt(604), // legendaryGemsValue
    BigInt(10) ** BigInt(27) * BigInt(4000) // mythicGemsValue
  );

  // Wait for the transaction to be mined
  await tx.wait();

  console.log("GemFactory initialized");

  await GemFactory.setGemsMiningPeriods(
    BigInt(1 * 7 * 24 * 60 * 60), // CommonGemsMiningPeriod (1 week)
    BigInt(2 * 7 * 24 * 60 * 60), // RareGemsMiningPeriod (2 weeks)
    BigInt(3 * 7 * 24 * 60 * 60), // UniqueGemsMiningPeriod (3 weeks)
    BigInt(4 * 7 * 24 * 60 * 60), // EpicGemsMiningPeriod (4 weeks)
    BigInt(5 * 7 * 24 * 60 * 60), // LegendaryGemsMiningPeriod (5 weeks)
    BigInt(6 * 7 * 24 * 60 * 60)  // MythicGemsMiningPeriod (6 weeks)
  );
  console.log("Gems Mining Periods set");

  // Set Gems Cooldown Periods
  await GemFactory.setGemsCooldownPeriods(
    BigInt(1 * 7 * 24 * 60 * 60), // CommonGemsCooldownPeriod (1 week)
    BigInt(2 * 7 * 24 * 60 * 60), // RareGemsCooldownPeriod (2 weeks)
    BigInt(3 * 7 * 24 * 60 * 60), // UniqueGemsCooldownPeriod (3 weeks)
    BigInt(4 * 7 * 24 * 60 * 60), // EpicGemsCooldownPeriod (4 weeks)
    BigInt(5 * 7 * 24 * 60 * 60), // LegendaryGemsCooldownPeriod (5 weeks)
    BigInt(6 * 7 * 24 * 60 * 60)  // MythicGemsCooldownPeriod (6 weeks)
  );
  console.log("Gems Cooldown Periods set");

  // Set Mining Trys
  await GemFactory.setminingTrys(
    BigInt(1),  // commonminingTry
    BigInt(2),  // rareminingTry
    BigInt(1),  // uniqueminingTry
    BigInt(10), // epicminingTry
    BigInt(15), // legendaryminingTry
    BigInt(20)  // mythicminingTry
  );
  console.log("Mining Trys set");

  // Initialize MarketPlace
  await MarketPlace.initialize(
    treasuryAddress,
    gemFactoryAddress,
    BigInt(10), // tonFeesRate (10%)
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS // l2ton
  );
  console.log("MarketPlace initialized");

  // Set MarketPlace Address in GemFactory
  await GemFactory.setMarketPlaceAddress(marketPlaceAddress);
  console.log("MarketPlace address set in GemFactory");

  await Treasury.setMarketPlace(marketPlaceAddress);
  console.log("MarketPlace address set in Treasury");

  // Approve GemFactory to spend Treasury WSTON
  await Treasury.approveGemFactory();
  console.log("GemFactory approved to spend Treasury WSTON");

  // Approve MarketPlace to spend Treasury WSTON
  await Treasury.approveMarketPlace();
  console.log("MarketPlace approved to spend Treasury WSTON");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
