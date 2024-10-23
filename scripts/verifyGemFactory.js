const { ethers, run } = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    const gemFactoryProxyAddress = process.env.GEM_FACTORY_PROXY;

    // Verify RandomPack
    await run("verify:verify", {
        address: gemFactoryProxyAddress,
        constructorArguments: [],
    });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
