const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("collect Gem with the account:", deployer.address);
  const gemFactoryProxy = process.env.GEM_FACTORY_PROXY;
  const drbCoordinatorAddress = process.env.DRB_COORDINATOR_MOCK;

  // Get contract instance
  const GemFactoryMining = await ethers.getContractAt("GemFactoryMining", gemFactoryProxy);

  
  try {

    const drbInitializeTx = await GemFactoryMining.DRBInitialize(
        drbCoordinatorAddress
      );
      await drbInitializeTx.wait();
      console.log("GemFactoryMining DRB initialized");


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