const { ethers } = require("hardhat");
require('dotenv').config();
// command to run: "source .env"
// command to run: "npx hardhat run scripts/utils/setAddresses.js --network thanos"

async function main() {
  const [deployer] = await ethers.getSigners();

  
  // Fetch environment variables

  const gemFactoryProxyAddress = process.env.GEM_FACTORY_PROXY;
  const treasuryProxyAddress = process.env.TREASURY_PROXY;


  
  // Get contract instances
  const GemFactory = await ethers.getContractAt("GemFactory", gemFactoryProxyAddress);
  await GemFactory.addColor("Amber & Amethyst",1,6,100,153,74,102,0,204);


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
