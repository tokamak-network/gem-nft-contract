const { ethers, run } = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    const treasuryAddress = process.env.TREASURY;
    const wstonAddress = process.env.TITAN_WRAPPED_STAKED_TON;
    const tonAddress = process.env.TON_ADDRESS;

    // Deploy WstonSwapPool
    const WstonSwapPool = await ethers.getContractFactory("WstonSwapPool");
    const wstonSwapPool = await WstonSwapPool.deploy(
        wstonAddress, // l2wston
        tonAddress, // l2ton
        10n ** 27n, // stakingIndex
        treasuryAddress, // treasury
        30 // swapPoolfeeRate
    );
    await wstonSwapPool.waitForDeployment(); // Ensure deployment is complete
    console.log("wstonSwapPool deployed to:", wstonSwapPool.target);

    // Verify RandomPack
    await run("verify:verify", {
        address: wstonSwapPool.target,
        constructorArguments: [
            wstonAddress, // l2wston
            tonAddress, // l2ton
            10n ** 27n, // stakingIndex
            treasuryAddress, // treasury
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
