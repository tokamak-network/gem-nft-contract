const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Connected with the account:", deployer.address);

  // Fetch environment variables
  const treasuryAddress = process.env.TREASURY;
  const marketPlaceAddress = process.env.MARKETPLACE;

  // Get contract instances
  const Treasury = await ethers.getContractAt("Treasury", treasuryAddress);

  await Treasury.transferWSTON("0x15759359e60a3b9e59eA7A96D10Fa48829f83bEb",BigInt(2500000000000000000000000000000));

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
