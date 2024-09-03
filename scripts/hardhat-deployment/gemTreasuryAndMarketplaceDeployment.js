const { ethers, run } = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    const gemfactoryAddress = process.env.GEM_FACTORY

    // Deploy Treasury
    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = await Treasury.deploy(
        process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
        process.env.TON_ADDRESS, // l2ton
        gemfactoryAddress // gemFactory
    );
    await treasury.waitForDeployment(); // Ensure deployment is complete
    console.log("Treasury deployed to:", treasury.target);

    // Verify Treasury
    await run("verify:verify", {
        address: treasury.target,
        constructorArguments: [
        process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
        process.env.TON_ADDRESS, // l2ton
        gemfactoryAddress // gemFactory
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
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
