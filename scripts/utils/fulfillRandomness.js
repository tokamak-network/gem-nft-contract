const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("fullfilRandomness with the account:", deployer.address);
  const drbCoordinatorAddress = process.env.DRB_COORDINATOR_MOCK;

  // Get contract instance
  const DrbCoordinator = await ethers.getContractAt("DRBCoordinatorMock", drbCoordinatorAddress);

  
  try {
    const tx = await DrbCoordinator.fulfillRandomness(295, {
        gasLimit: 300000,
    });
    await tx.wait();
    console.log("fullFillRandomness called");


  } catch (error) {
    console.error("Error:", error);
    if (error.data) {
      console.error("Revert reason:", ethers.utils.toUtf8String(error.data));
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error:", error);
    process.exit(1);
  });