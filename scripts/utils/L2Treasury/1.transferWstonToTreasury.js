
const { ethers } = require("hardhat");
require('dotenv').config();

// npx hardhat run scripts/utils/L2Treasury/1.transferWstonToTreasury.js --network thanos

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Minting GEMs with the account:", deployer.address);
    const treasuryProxyAddress = process.env.TREASURY_PROXY;
    const l2wstonAddress = process.env.THANOS_WRAPPED_STAKED_TON;

    // Get contract instance
    const Treasury = await ethers.getContractAt("TreasuryThanos", treasuryProxyAddress);

    // Thanos WSTON Contract ABI
    const wstonABI = [
        "function transfer(address to, uint256 value) public returns (bool)"
    ];

    // Create a contract instance for the TON token
    const L2Wston = new ethers.Contract(l2wstonAddress, wstonABI, deployer);

    // Define the amount to deposit (in TON)
    const wstonAmount = ethers.parseUnits('10000', 27); 


    try {

        // Call the transfer function
        console.log("transfer wston to the treasury...");
        const tx = await L2Wston.transfer(treasuryProxyAddress, wstonAmount);
        console.log('transfer transaction sent:', tx.hash);

        // Wait for the transaction to be mined
        const receipt = await tx.wait();
        console.log('transfer transaction mined:', receipt.transactionHash);

    } catch (error) {
        console.error('Error depositing TON:', error);
    }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error:", error);
    process.exit(1);
  });