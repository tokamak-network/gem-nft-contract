require('dotenv').config();
const { AwsKmsSigner } = require("ethers-aws-kms-signer");
const { ethers, WebSocketProvider, JsonRpcProvider, Contract } = require("ethers");

const kmsCredentials = {
    accessKeyId:"AKIA5JMSUE2IH2AE6WEE", // credentials for your IAM user with KMS access
    secretAccessKey:"eOFNk23tjC34i2MKFZOdEFiSC0qIPfJDvMTzQ3WP", // credentials for your IAM user with KMS access
    region:"us-east-1",
    keyId:"arn:aws:kms:us-east-1:913524926096:key/aa8fbf58-6c60-438d-a203-b270756d8273",
};

// Load environment variables
const {
    SEPOLIA_RPC_URL,
    TITAN_SEPOLIA_RPC_URL,
    L1_WRAPPED_STAKED_TON,
    WSTON_SWAP_POOL
} = process.env;

// Log the environment variables to ensure they are loaded correctly
console.log("L1_WRAPPED_STAKED_TON:", L1_WRAPPED_STAKED_TON);
console.log("WSTON_SWAP_POOL:", WSTON_SWAP_POOL);

// ABI of the L1 contract
const L1_ABI = [
    "event Deposited(address to, uint256 amount, uint256 wstonAmount, uint256 depositTime, uint256 depositBlockNumber)",
    "function stakingIndex() view returns (uint256)" // Assuming stakingIndex is a public variable or has a getter function
];

// ABI of the L2 contract
const L2_ABI = [
    "function updateStakingIndex(uint256 newIndex) external",
];

// Providers
const l1Provider = new WebSocketProvider(SEPOLIA_RPC_URL); // Use WebSocketProvider for wss:// URLs
const l2Provider = new JsonRpcProvider(TITAN_SEPOLIA_RPC_URL);

let l2Signer = new AwsKmsSigner(kmsCredentials);
l2Signer = l2Signer.connect(l2Provider);

// Contract instances
const l1Contract = new Contract(L1_WRAPPED_STAKED_TON, L1_ABI, l1Provider);
const l2Contract = new Contract(WSTON_SWAP_POOL, L2_ABI, l2Signer);

// Listen to events from L1 and update L2
l1Contract.on("Deposited", async (to, amount, wstonAmount, depositTime, depositBlockNumber) => {
    console.log(`Deposited event detected: to=${to}, amount=${amount}, wstonAmount=${wstonAmount}, depositTime=${depositTime}, depositBlockNumber=${depositBlockNumber}`);
    try {
        // Read the stakingIndex from the L1 contract
        const stakingIndex = await l1Contract.stakingIndex();
        console.log(`Read stakingIndex from L1: stakingIndex=${stakingIndex}`);

        // Call updateStakingIndex on the L2 contract with the stakingIndex
        const tx = await l2Contract.updateStakingIndex(stakingIndex);
        await tx.wait();
        console.log(`L2 staking index updated: stakingIndex=${stakingIndex}`);
    } catch (error) {
        console.error(`Failed to update L2 data: ${error}`);
    }
});

console.log("Oracle is listening for events...");
