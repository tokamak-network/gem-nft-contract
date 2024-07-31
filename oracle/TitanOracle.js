require('dotenv').config();
const { JsonRpcProvider, Wallet, Contract } = require('ethers');

// Load environment variables
const {
    SEPOLIA_RPC_URL,
    TIITAN_SEPOLIA_RPC_URL,
    PRIVATE_KEY,
    L1_CONTRACT_ADDRESS,
    L2_CONTRACT_ADDRESS
} = process.env;

// Check if environment variables are loaded correctly
if (!SEPOLIA_RPC_URL || !TIITAN_SEPOLIA_RPC_URL || !PRIVATE_KEY || !L1_CONTRACT_ADDRESS || !L2_CONTRACT_ADDRESS) {
    console.error("Please ensure all environment variables are set correctly.");
    process.exit(1);
}

// ABI of the L1 contract
const L1_ABI = [
    "event Deposited(uint256 indexed stakingIndex, address indexed account, uint256 amount, uint256 depositTime)"
];

// ABI of the L2 contract
const L2_ABI = [
    "function onWSTONDeposit(uint256 _amount, uint256 _stakingIndex, uint256 _depositTime) external"
];

// Providers
const l1Provider = new JsonRpcProvider(SEPOLIA_RPC_URL);
const l2Provider = new JsonRpcProvider(TIITAN_SEPOLIA_RPC_URL);

// Signer for L2 (must have private key with funds on L2)
const l2Signer = new Wallet(PRIVATE_KEY, l2Provider);

// Contract instances
const l1Contract = new Contract(L1_CONTRACT_ADDRESS, L1_ABI, l1Provider);
const l2Contract = new Contract(L2_CONTRACT_ADDRESS, L2_ABI, l2Signer);

// Listen to events from L1 and update L2
l1Contract.on("Deposited", async (stakingIndex, account, amount, depositTime) => {
    console.log(`Deposited event detected: stakingIndex=${stakingIndex}, account=${account}, amount=${amount}, depositTime=${depositTime}`);
    try {
        const tx = await l2Contract.onWSTONDeposit(amount, stakingIndex, depositTime);
        await tx.wait();
        console.log(`L2 data updated: stakingIndex=${stakingIndex}, account=${account}, amount=${amount}, depositTime=${depositTime}`);
    } catch (error) {
        console.error(`Failed to update L2 data: ${error}`);
    }
});

console.log("Oracle is listening for events...");
