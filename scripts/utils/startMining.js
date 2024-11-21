const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("start mining with the account:", deployer.address);
  const gemFactoryProxy = process.env.GEM_FACTORY_PROXY;

  // Get contract instance
  const GemFactoryMining = await ethers.getContractAt("GemFactoryMining", gemFactoryProxy);

  
  try {
   
    const tx = await GemFactoryMining.startMiningGEM(36, {
        gasLimit: 15000000 
      });
    await tx.wait();
    console.log("Token started Mining");


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