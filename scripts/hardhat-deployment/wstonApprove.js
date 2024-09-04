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
    "0x9dbFDA1De782a918E8d8e9c355da830A5ee70d6E",
    1000000000000000000000000000000n
  );
  console.log("approve is sucessful");

  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
