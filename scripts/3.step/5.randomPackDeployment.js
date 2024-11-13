const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/3.step/5.randomPackDeployment.js --network titan"

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

    // Deploy RandomPackProxy
    const RandomPackProxy = await ethers.getContractFactory("RandomPackProxy");
    const randomPackProxy = await RandomPackProxy.deploy();
    await randomPackProxy.waitForDeployment(); // Ensure deployment is complete
    console.log("randomPackProxy deployed to:", randomPackProxy.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    // Verify Treasury
    await run("verify:verify", {
      address: randomPackProxy.target,
      constructorArguments: [],
      contract:"src/L2/RandomPackProxy.sol:RandomPackProxy"
    });
    console.log("RandomPackProxy verified");

    // Set the first index to the GemFactory contract
    const upgradeTo = await randomPackProxy.upgradeTo(randomPack.target);
    await upgradeTo.wait();
    console.log("randomPackProxy upgraded to randomPack");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
