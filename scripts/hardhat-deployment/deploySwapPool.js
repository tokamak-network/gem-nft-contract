const { ethers, run } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance));

  // Deploy WstonSwapPool
  const WstonSwapPool = await ethers.getContractFactory("WstonSwapPool");
  const wstonSwapPool = await WstonSwapPool.deploy(
    process.env.TON_ADDRESS, // l2ton
    process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
    10n ** 27n, // stakingIndex
    process.env.TREASURY, // treasury
    30 // swapPoolfeeRate
  );
  await wstonSwapPool.waitForDeployment(); // Ensure deployment is complete
  console.log("WstonSwapPool deployed to:", wstonSwapPool.target);

  // Verify WstonSwapPool
  await run("verify:verify", {
    address: wstonSwapPool.target,
    constructorArguments: [
      process.env.TON_ADDRESS, // l2ton
      process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
      10n ** 27n, // stakingIndex
      process.env.TREASURY, // treasury
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
