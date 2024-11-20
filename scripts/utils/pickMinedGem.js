const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("start mining with the account:", deployer.address);
  const gemFactoryProxy = process.env.GEM_FACTORY_PROXY;

  // Get contract instance
  const GemFactoryMining = await ethers.getContractAt("GemFactoryMining", gemFactoryProxy);

  
  try {
    // Convert 0.005 ETH to wei
    const ethValue = ethers.parseUnits('0.005', 'ether');
    const tx = await GemFactoryMining.pickMinedGEM(7, {
        gasLimit: 15000000,
        value: ethValue
    });
    await tx.wait();
    console.log("PickMinedGem called");


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