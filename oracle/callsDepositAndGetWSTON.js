require('dotenv').config();
const { ethers } = require('ethers');

// Load environment variables
const {
    SEPOLIA_RPC_URL,
    PRIVATE_KEY,
    L1_CONTRACT_ADDRESS,
    L1_WSTON_ADDRESS
} = process.env;

// Check if environment variables are loaded correctly
if (!SEPOLIA_RPC_URL || !PRIVATE_KEY || !L1_CONTRACT_ADDRESS || !L1_WSTON_ADDRESS) {
    console.error("Please ensure all environment variables are set correctly.");
    process.exit(1);
}

// ABI of the L1 contract
const L1_ABI = [
    "function depositAndGetWSWTON(uint256 _amount, uint256 _layer2Index) external",
];

// ABI of the ERC20 contract (for approve function)
const ERC20_ABI = [
    "function approve(address spender, uint256 amount) external returns (bool)",
];

// Providers
const provider = new ethers.JsonRpcProvider(SEPOLIA_RPC_URL);

// Signer (must have private key with funds on L1)
const signer = new ethers.Wallet(PRIVATE_KEY, provider);

// Contract instances
const l1Contract = new ethers.Contract(L1_CONTRACT_ADDRESS, L1_ABI, signer);
const l1WstonContract = new ethers.Contract(L1_WSTON_ADDRESS, ERC20_ABI, signer);

// Function to call approve and then depositAndGetWSWTON
async function callApproveAndDeposit(amount, layer2Index) {
    try {
        // Approve the L1 contract to spend the specified amount of WSTON
        const approveTx = await l1WstonContract.approve(L1_CONTRACT_ADDRESS, amount);
        console.log(`Approve transaction hash: ${approveTx.hash}`);
        await approveTx.wait();
        console.log(`Approve transaction confirmed: ${approveTx.hash}`);

        // Call depositAndGetWSWTON
        const depositTx = await l1Contract.depositAndGetWSWTON(amount, layer2Index);
        console.log(`Deposit transaction hash: ${depositTx.hash}`);
        await depositTx.wait();
        console.log(`Deposit transaction confirmed: ${depositTx.hash}`);
    } catch (error) {
        console.error(`Failed to call approve and depositAndGetWSWTON: ${error}`);
    }
}

// Example usage
const amount = ethers.parseUnits("10.0", 27); // Adjust the amount and decimals as needed
const layer2Index = 0; // Adjust the layer2Index as needed

callApproveAndDeposit(amount, layer2Index);
