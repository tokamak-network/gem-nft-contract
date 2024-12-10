const { ethers } = require("hardhat");
require('dotenv').config();

// npx hardhat run scripts/utils/putGemListForSale.js --network thanos

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Connected with the account:", deployer.address);

  // Fetch environment variables
  const treasuryAddress = process.env.TREASURY_PROXY;
  const marketPlaceAddress = process.env.MARKETPLACE_PROXY;

  // Get contract instance
  const Treasury = await ethers.getContractAt("Treasury", treasuryAddress);

  // Prepare arrays for token IDs and prices
  const tokenIds = [];
  const prices = [];
  const fixedPrice = ethers.parseUnits("11", 27); // 10 * 10^27

  for (let gemId = 200; gemId <= 270; gemId++) {
    tokenIds.push(gemId);
    prices.push(fixedPrice);

    // Call approveGem for each tokenId
    try {
      await Treasury.approveGem(marketPlaceAddress, gemId);
      console.log(`approveGem successful for Gem ID: ${gemId}`);
    } catch (error) {
      console.error(`Error approving Gem ID ${gemId}:`, error);
    }
  }

  // Call putGemListForSale after all approvals are done
  try {
    // await Treasury.putGemListForSale(tokenIds, prices);
    const tx = await Treasury.putGemListForSale(tokenIds, prices, {
      gasLimit: 15000000 
    });
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