const { ethers, run } = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    // Deploy RandomPack
    const RandomPack = await ethers.getContractFactory("RandomPack");
    const randomPack = await RandomPack.deploy();
    await randomPack.waitForDeployment(); // Ensure deployment is complete
    console.log("RandomPack deployed to:", randomPack.target);

    // Verify RandomPack
    await run("verify:verify", {
        address: randomPack.target,
        constructorArguments: [],
    });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
