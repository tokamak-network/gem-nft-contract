const { ethers, run } = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    const coordinatorAddress = process.env.DRB_COORDINATOR_MOCK;
    const gemFactoryAddress = process.env.GEM_FACTORY;
    const treasuryAddress = process.env.TREASURY;
    const tonAddress = process.env.TON_ADDRESS
    const randomPackFees = 25000000000000000000n;

    // Deploy RandomPack
    const RandomPack = await ethers.getContractFactory("RandomPack");
    const randomPack = await RandomPack.deploy(
        coordinatorAddress,
        tonAddress,
        gemFactoryAddress,
        treasuryAddress,
        randomPackFees
    );
    await randomPack.waitForDeployment(); // Ensure deployment is complete
    console.log("RandomPack deployed to:", randomPack.target);

    // Verify RandomPack
    await run("verify:verify", {
        address: randomPack.target,
        constructorArguments: [
            coordinatorAddress,
            tonAddress,
            gemFactoryAddress,
            treasuryAddress,
            randomPackFees
        ],
    });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
