const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Transfering GEMs with the account:", deployer.address);
  const treasuryAddress = process.env.TREASURY_PROXY;

  // Get contract instance
  const Treasury = await ethers.getContractAt("Treasury", treasuryAddress);

  try {
    console.log("Transfering treasury Gem to...");

    // Call createPreminedGEMPool
    const tx = await Treasury.transferTreasuryGEMto("0x15759359e60a3b9e59eA7A96D10Fa48829f83bEb", 7);
    await tx.wait();
    console.log("Token sent");
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