const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("settign cooldown period with the account:", deployer.address);
  const gemFactoryProxy = process.env.GEM_FACTORY_PROXY;

  // Get contract instance
  const GemFactory = await ethers.getContractAt("GemFactory", gemFactoryProxy);

  
  try {
    // Set Gems Cooldown Periods
    await GemFactory.setGemsCooldownPeriods(
        BigInt(1), 
        BigInt(1), 
        BigInt(1), 
        BigInt(1), 
        BigInt(1),  
        {gasLimit: 1000000}
    );
    console.log("Gems Cooldown Periods set");

    await GemFactory.setGemsMiningPeriods(
        BigInt(1), 
        BigInt(1),
        BigInt(1),
        BigInt(1),
        BigInt(1),
        {gasLimit: 1000000}
      );
      console.log("Gems Mining Periods set");

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