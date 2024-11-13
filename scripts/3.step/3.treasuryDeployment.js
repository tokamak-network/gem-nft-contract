const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/3.step/3.treasuryDeployment.js --network titan"

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    // Instantiate the Treasury
    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = await Treasury.deploy();
    await treasury.waitForDeployment();
    console.log("treasury deployed to:", treasury.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    await run("verify:verify", {
      address: treasury.target,
      constructorArguments: [],
      contract:"src/L2/Treasury.sol:Treasury"
    });


    // Deploy Treasury Proxy
    const TreasuryProxy = await ethers.getContractFactory("TreasuryProxy");
    const treasuryProxy = await TreasuryProxy.deploy();
    await treasuryProxy.waitForDeployment(); // Ensure deployment is complete
    console.log("TreasuryProxy deployed to:", treasuryProxy.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    // Verify Treasury
    await run("verify:verify", {
      address: treasuryProxy.target,
      constructorArguments: [],
      contract:"src/L2/TreasuryProxy.sol:TreasuryProxy"
    });
    console.log("TreasuryProxy verified");

    // Set the first index to the GemFactory contract
    const upgradeTo = await treasuryProxy.upgradeTo(treasury.target);
    await upgradeTo.wait();
    console.log("treasuryProxy upgraded to Treaury");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
