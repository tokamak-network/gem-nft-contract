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

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
