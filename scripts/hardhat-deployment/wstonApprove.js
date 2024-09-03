const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Initializing GemFactory with the account:", deployer.address);

  // Fetch environment variables
  const wstonAddress = process.env.TITAN_WRAPPED_STAKED_TON;

  // Get contract instances
  const Wston = await ethers.getContractAt("L2StandardERC20", wstonAddress);

  await Wston.approve(
    "0x06aD364247B4F8e491Ce401B6DD7552B8eD289dE",
    4000000000000000000000000000000n
  );
  console.log("approve is sucessful");

  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
