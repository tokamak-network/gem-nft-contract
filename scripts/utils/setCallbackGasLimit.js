const { ethers } = require("hardhat");
require('dotenv').config();

// npx hardhat run scripts/utils/setCooldownPeriod.js --network thanos

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("setting new callback gas limit in GemFactoryProxy:", deployer.address);
  const gemFactoryProxyAddress = process.env.GEM_FACTORY_PROXY;

  // Get contract instance
  const GemFactory = await ethers.getContractAt("GemFactory", gemFactoryProxyAddress);

  
  try {
    // Set Gems Cooldown Periods
    await GemFactory.setCallbackGasLimit(
        4000000n,
        {gasLimit: 1000000}
    );
    console.log("callback gas limit set");

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