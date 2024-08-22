const { ethers, run } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance));

  // Deploy DRBCoordinatorMock
  const DRBCoordinatorMock = await ethers.getContractFactory("DRBCoordinatorMock");
  const drbCoordinatorMock = await DRBCoordinatorMock.deploy(
    2100000, // avgL2GasUsed
    0,       // premiumPercentage
    ethers.parseEther("0.001"), // flatFee
    2071     // calldataSizeBytes
  );
  await drbCoordinatorMock.waitForDeployment(); // Ensure deployment is complete
  console.log("DRBCoordinatorMock deployed to:", drbCoordinatorMock.target);

  // Verify DRBCoordinatorMock
  await run("verify:verify", {
    address: drbCoordinatorMock.target,
    constructorArguments: [
      2100000, // avgL2GasUsed
      0,       // premiumPercentage
      ethers.parseEther("0.001"), // flatFee
      2071     // calldataSizeBytes
    ],
  });

  // Deploy GemFactory
  const GemFactory = await ethers.getContractFactory("GemFactory");
  const gemFactory = await GemFactory.deploy(drbCoordinatorMock.target);
  await gemFactory.waitForDeployment(); // Ensure deployment is complete
  console.log("GemFactory deployed to:", gemFactory.target);

  // Verify GemFactory
  await run("verify:verify", {
    address: gemFactory.target,
    constructorArguments: [drbCoordinatorMock.target],
  });

  // Deploy Treasury
  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.deploy(
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS, // l2ton
    gemFactory.target // gemFactory
  );
  await treasury.waitForDeployment(); // Ensure deployment is complete
  console.log("Treasury deployed to:", treasury.target);

  // Verify Treasury
  await run("verify:verify", {
    address: treasury.target,
    constructorArguments: [
      process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
      process.env.TON_ADDRESS, // l2ton
      gemFactory.target // gemFactory
    ],
  });

  // Deploy MarketPlace
  const MarketPlace = await ethers.getContractFactory("MarketPlace");
  const marketPlace = await MarketPlace.deploy();
  await marketPlace.waitForDeployment(); // Ensure deployment is complete
  console.log("MarketPlace deployed to:", marketPlace.target);

  // Verify MarketPlace
  await run("verify:verify", {
    address: marketPlace.target,
    constructorArguments: [],
  });

  // Deploy WstonSwapPool
  const WstonSwapPool = await ethers.getContractFactory("WstonSwapPool");
  const wstonSwapPool = await WstonSwapPool.deploy(
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS, // l2ton
    10n ** 27n, // stakingIndex
    treasury.target, // treasury
    30 // swapPoolfeeRate
  );
  await wstonSwapPool.waitForDeployment(); // Ensure deployment is complete
  console.log("WstonSwapPool deployed to:", wstonSwapPool.target);

  // Verify WstonSwapPool
  await run("verify:verify", {
    address: wstonSwapPool.target,
    constructorArguments: [
      process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
      process.env.TON_ADDRESS, // l2ton
      10n ** 27n, // stakingIndex
      treasury.target, // treasury
      30 // swapPoolfeeRate
    ],
  });

  // Initialize GemFactory
  await gemFactory.initialize(
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS, // l2ton
    treasury.target, // treasury
    (10n ** 27n) * 10, // commonGemsValue
    (10n ** 27n) * 19, // rareGemsValue
    (10n ** 27n) * 53, // uniqueGemsValue
    (10n ** 27n) * 204, // epicGemsValue
    (10n ** 27n) * 604, // legendaryGemsValue
    (10n ** 27n) * 4000 // mythicGemsValue
  );
  console.log("GemFactory initialized");

  // Set Gems Mining Periods
  await gemFactory.setGemsMiningPeriods(
    1 * 7 * 24 * 60 * 60, // CommonGemsMiningPeriod (1 week)
    2 * 7 * 24 * 60 * 60, // RareGemsMiningPeriod (2 weeks)
    3 * 7 * 24 * 60 * 60, // UniqueGemsMiningPeriod (3 weeks)
    4 * 7 * 24 * 60 * 60, // EpicGemsMiningPeriod (4 weeks)
    5 * 7 * 24 * 60 * 60, // LegendaryGemsMiningPeriod (5 weeks)s
    6 * 7 * 24 * 60 * 60  // MythicGemsMiningPeriod (6 weeks)
  );
  console.log("Gems Mining Periods set");

  // Set Gems Cooldown Periods
  await gemFactory.setGemsCooldownPeriods(
    1 * 7 * 24 * 60 * 60, // CommonGemsCooldownPeriod (1 week)
    2 * 7 * 24 * 60 * 60, // RareGemsCooldownPeriod (2 weeks)
    3 * 7 * 24 * 60 * 60, // UniqueGemsCooldownPeriod (3 weeks)
    4 * 7 * 24 * 60 * 60, // EpicGemsCooldownPeriod (4 weeks)
    5 * 7 * 24 * 60 * 60, // LegendaryGemsCooldownPeriod (5 weeks)
    6 * 7 * 24 * 60 * 60  // MythicGemsCooldownPeriod (6 weeks)
  );
  console.log("Gems Cooldown Periods set");

  // Set Mining Trys
  await gemFactory.setminingTrys(
    1,  // commonminingTry
    2,  // rareminingTry
    1,  // uniqueminingTry
    10, // epicminingTry
    15, // legendaryminingTry
    20  // mythicminingTry
  );
  console.log("Mining Trys set");

  // Initialize MarketPlace
  await marketPlace.initialize(
    treasury.target,
    gemFactory.target,
    10, // tonFeesRate (10%)
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    process.env.TON_ADDRESS // l2ton
  );
  console.log("MarketPlace initialized");

  // Set MarketPlace Address in GemFactory
  await gemFactory.setMarketPlaceAddress(marketPlace.target);
  console.log("MarketPlace address set in GemFactory");

  // Set MarketPlace Address in Treasury
  await treasury.setMarketPlace(marketPlace.target);
  console.log("MarketPlace address set in Treasury");

  // Approve GemFactory to spend Treasury WSTON
  await treasury.approveGemFactory();
  console.log("GemFactory approved to spend Treasury WSTON");

  // Approve MarketPlace to spend Treasury WSTON
  await treasury.approveMarketPlace();
  console.log("MarketPlace approved to spend Treasury WSTON");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
