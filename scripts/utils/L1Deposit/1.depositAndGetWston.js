
const { ethers } = require("hardhat");
require('dotenv').config();

// npx hardhat run scripts/utils/L1Deposit/1.depositAndGetWston.js --network sepolia

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Minting GEMs with the account:", deployer.address);
    const l1wstonProxyAddress = process.env.L1_WRAPPED_STAKED_TON_PROXY;
    const tonTokenAddress = process.env.L1_TON;

    // Get contract instance
    const Wston = await ethers.getContractAt("L1WrappedStakedTON", l1wstonProxyAddress);

    // TON Token Contract ABI (simplified for approve function)
    const tonTokenABI = [
        "function approve(address spender, uint256 amount) external returns (bool)"
    ];

    // Create a contract instance for the TON token
    const tonTokenContract = new ethers.Contract(tonTokenAddress, tonTokenABI, deployer);

    // Define the amount to deposit (in TON)
    const tonAmount = ethers.parseUnits('50000', 'ether'); 


    try {

        // Call the approve function
        console.log("approving ton...");
        const tx = await tonTokenContract.approve(l1wstonProxyAddress, tonAmount);
        console.log('Approval transaction sent:', tx.hash);

        // Wait for the transaction to be mined
        const receipt = await tx.wait();
        console.log('Approval transaction mined:', receipt.transactionHash);

        console.log("depositing Ton for Wston...");

        // Call the deposit function
        const tx1 = await Wston.depositWTONAndGetWSTON(tonAmount, true, {
            gasLimit: 15000000 
        }); // true indicates TON
        console.log('Transaction sent:', tx.hash);

        // Wait for the transaction to be confirmed
        const receipt1 = await tx1.wait();
        console.log("Transaction successful, receipt:", receipt1);
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