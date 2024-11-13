const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/3.step/2.drbCoordinatorMock.js --network titan"

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", await deployer.getAddress());

    const balance = await ethers.provider.getBalance(await deployer.getAddress());
    console.log("Account balance:", ethers.formatEther(balance));


    // ------------------------ DRBCOORDINATOR MOCK ---------------------------------

    const DrbCoordinator = await ethers.getContractFactory("DRBCoordinatorMock");
    const drbCoordinator = await DrbCoordinator.deploy(
        BigInt(2100000), // avgL2GasUsed
        BigInt(0), //premiumPercentage
        ethers.parseEther("0.001"), // flatFee
        BigInt(2071)     // calldataSizeBytes
    );
    await drbCoordinator.waitForDeployment();
    console.log("DrbCoordinator deployed to:", drbCoordinator.target);

    // verifying the contract
    await run("verify:verify", {
        address: drbCoordinator.target,
        constructorArguments: [
            BigInt(2100000), // avgL2GasUsed
            BigInt(0), //premiumPercentage
            ethers.parseEther("0.001"), // flatFee
            BigInt(2071)     // calldataSizeBytes
        ],
        contract:"src/L2/Mock/DRBCoordinatorMock.sol:DRBCoordinatorMock"
      });
    console.log("DrbCoordinator verified successfully");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
