const { ethers, run } = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    const coordinatorAddress = process.env.DRB_COORDINATOR_MOCK;

     // Deploy ForgeLibrary
     const ForgeLibrary = await ethers.getContractFactory("ForgeLibrary");
     const forgeLibrary = await ForgeLibrary.deploy();
     await forgeLibrary.waitForDeployment();
     console.log("ForgeLibrary deployed to:", forgeLibrary.target);

     // Deploy MiningLibrary
     const MiningLibrary = await ethers.getContractFactory("MiningLibrary");
     const miningLibrary = await MiningLibrary.deploy();
     await miningLibrary.waitForDeployment();
     console.log("miningLibrary deployed to:", miningLibrary.target);

     // Deploy GemLibrary
     const GemLibrary = await ethers.getContractFactory("GemLibrary");
     const gemLibrary = await GemLibrary.deploy();
     await gemLibrary.waitForDeployment();
     console.log("gemLibrary deployed to:", gemLibrary.target);
 
     // Deploy GemFactory with linked ForgeLibrary
     const GemFactory = await ethers.getContractFactory("GemFactory");
    const gemFactory = await GemFactory.deploy();
    await gemFactory.waitForDeployment(); // Ensure deployment is complete
    console.log("GemFactory deployed to:", gemFactory.target);



    // Verify GemFactory
    await run("verify:verify", {
    address: gemFactory.target,
    constructorArguments: [],
    });

    // Deploy Treasury
  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.deploy();
  await treasury.waitForDeployment(); // Ensure deployment is complete
  console.log("Treasury deployed to:", treasury.target);

  // Verify Treasury
  await run("verify:verify", {
    address: treasury.target,
    constructorArguments: [],
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

  /*// Deploy WstonSwapPool
  const WstonSwapPool = await ethers.getContractFactory("WstonSwapPool");
  const wstonSwapPool = await WstonSwapPool.deploy(
    process.env.TON_ADDRESS, // l2ton
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
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
  */
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
