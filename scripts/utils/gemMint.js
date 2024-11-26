const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Minting GEMs with the account:", deployer.address);
  const treasuryAddress = process.env.TREASURY_PROXY;

  // Get contract instance
  const Treasury = await ethers.getContractAt("Treasury", treasuryAddress);

  // Prepare input parameters for the createPreminedGEMPool function
  const rarities = [0, 0, 0, 0, 0]; // Adjust this to match the enum type in Solidity
  const colors = [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4]];
  const quadrants = [
    [1, 2, 2, 1], 
    [1, 2, 2, 1], 
    [1, 2, 2, 1], 
    [1, 2, 2, 1], 
    [1, 2, 2, 1]
  ];
  const tokenURIs = ["", "", "", "", ""];

  try {
    console.log("Creating premined GEM pool...");

    // Call createPreminedGEMPool
    const tx = await Treasury.createPreminedGEMPool(rarities, colors, quadrants, tokenURIs, {
      gasLimit: 15000000 
    });
    console.log("Transaction sent:", tx.hash);

    // Wait for the transaction to be confirmed
    const receipt = await tx.wait();
    console.log("Transaction successful, receipt:", receipt);
  } catch (error) {
    console.error("Error creating GEM pool:", error);
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