const { ethers, run } = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    const gemFactoryProxyAddress = process.env.GEM_FACTORY_PROXY;
    const treasuryAddress = process.env.TREASURY;
    const MarketPlace = await ethers.getContractFactory("MarketPlace");
  /*
    // Deploy MarketPlace
    const marketPlace = await MarketPlace.deploy();
    await marketPlace.waitForDeployment(); // Ensure deployment is complete
    console.log("MarketPlace deployed to:", marketPlace.target);

    // Verify MarketPlace
    await run("verify:verify", {
      address: marketPlace.target,
      constructorArguments: [],
    });
*/
    // Call the MarketPlace initialize function
    const tx3 = await MarketPlace.initialize(
      treasuryAddress,
      gemFactoryProxyAddress,
      BigInt(10), // ton fee rate = 10
      process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
      process.env.TON_ADDRESS, // l2ton
    );
    await tx3.wait();
    console.log("MarketPlace initialized");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
