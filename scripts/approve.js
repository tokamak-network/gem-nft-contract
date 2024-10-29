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

  // Prepare arrays for token IDs and prices
  const tokenIds = [];
  const prices = [];
  const fixedPrice = ethers.BigNumber.from("11000000000000000000000000000"); // Price in Wei

  for (let gemId = 30; gemId <= 50; gemId++) {
    tokenIds.push(gemId);
    prices.push(fixedPrice);
  }

  try {
    await Treasury.putGemListForSale(tokenIds, prices);
    console.log("putGemListForSale is successful for Gem IDs 30 to 50");
  } catch (error) {
    console.error("Error putting Gem list for sale:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
