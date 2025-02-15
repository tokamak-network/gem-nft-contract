const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("start mining with the account:", deployer.address);
  const gemFactoryProxy = process.env.GEM_FACTORY_PROXY;

  // Get contract instance
  const GemFactoryForging = await ethers.getContractAt("GemFactoryForging", gemFactoryProxy);

  
  try {
   
    const tx = await GemFactoryForging.forgeTokens([152,192],0,[6,6], {
        gasLimit: 15000000 
      });
    await tx.wait();
    console.log("Token forged");


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