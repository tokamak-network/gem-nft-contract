const { ethers } = require("hardhat");
require('dotenv').config();

// npx hardhat run scripts/utils/setCooldownPeriod.js --network thanos

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("settign cooldown period with the account:", deployer.address);
  const gemFactoryProxy = process.env.GEM_FACTORY_PROXY;

  // Get contract instance
  const GemFactory = await ethers.getContractAt("GemFactory", gemFactoryProxy);

  
  try {
    // Set Gems Cooldown Periods
    await GemFactory.setGemsCooldownPeriods(
        BigInt(24 * 60 * 60), 
        BigInt(12 * 60 * 60), 
        BigInt(6 * 60 * 60), 
        BigInt(3 * 60 * 60), 
        BigInt(1 * 60 * 60),  
        {gasLimit: 1000000}
    );
    console.log("Gems Cooldown Periods set");

    await GemFactory.setGemsMiningPeriods(
        BigInt(10 * 60), 
        BigInt(10 * 60),
        BigInt(10 * 60),
        BigInt(10 * 60),
        BigInt(10 * 60),
        {gasLimit: 1000000}
      );
      console.log("Gems Mining Periods set");

    // Set Mining Trys
    await GemFactory.setMiningTries(
      BigInt(1),  // rareminingTry
      BigInt(2),  // uniqueminingTry
      BigInt(4), // epicminingTry
      BigInt(8), // legendaryminingTry
      BigInt(16),  // mythicminingTry
      {gasLimit: 1000000}
    );
    console.log("Mining Trys set");

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