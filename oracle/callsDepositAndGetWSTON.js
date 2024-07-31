require('dotenv').config();
const { ethers } = require('ethers');

// Load environment variables
const {
    SEPOLIA_RPC_URL,
    PRIVATE_KEY,
    L1_CONTRACT_ADDRESS
} = process.env;

// Check if environment variables are loaded correctly
if (!SEPOLIA_RPC_URL || !PRIVATE_KEY || !L1_CONTRACT_ADDRESS) {
    console.error("Please ensure all environment variables are set correctly.");
    process.exit(1);
}

// ABI of the L1 contract
const L1_ABI = [
    "function depositAndGetWSWTON(uint256 _amount, uint256 _layer2Index) external",
];

// Providers
const provider = new ethers.JsonRpcProvider(SEPOLIA_RPC_URL);

// Signer (must have private key with funds on L1)
const signer = new ethers.Wallet(PRIVATE_KEY, provider);

// Contract instance
const l1Contract = new ethers.Contract(L1_CONTRACT_ADDRESS, L1_ABI, signer);

// Function to call depositAndGetWSWTON
async function callDepositAndGetWSWTON(amount, layer2Index) {
    try {
        const tx = await l1Contract.depositAndGetWSWTON(amount, layer2Index);
        console.log(`Transaction hash: ${tx.hash}`);
        await tx.wait();
        console.log(`Transaction confirmed: ${tx.hash}`);
    } catch (error) {
        console.error(`Failed to call depositAndGetWSWTON: ${error}`);
    }
}

// Example usage
const amount = 1000000000000000000000000000; // Adjust the amount and decimals as needed
const layer2Index = 0; // Adjust the layer2Index as needed

callDepositAndGetWSWTON(amount, layer2Index);
