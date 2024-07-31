require('dotenv').config();
const { ethers } = require("ethers");
const axios = require("axios");

const L1WrappedStakedTONAddress = "L1WrappedStakedTON_CONTRACT_ADDRESS";
const L1WrappedStakedTONABI = [
    "event Deposited(uint256 indexed stakingIndex, address indexed account, uint256 amount, uint256 depositTime)"
];

const L2WSTONManagerAddress = "L2WSTONManager_CONTRACT_ADDRESS";
const L2WSTONManagerABI = [
    "function onWSTONDeposit(address _account,uint256 _amount,uint256 _stakingIndex,uint256 _depositTime) external"
];

// Connect to the L1 network
const l1Provider = new ethers.providers.JsonRpcProvider(process.env.L1_RPC_URL);
const l1Wallet = new ethers.Wallet(process.env.PRIVATE_KEY, l1Provider);

// Connect to the Optimistic Rollup (L2) network
const l2Provider = new ethers.providers.JsonRpcProvider(process.env.L2_RPC_URL);
const l2Wallet = new ethers.Wallet(process.env.PRIVATE_KEY, l2Provider);

const L1WrappedStakedTON = new ethers.Contract(L1WrappedStakedTONAddress, L1WrappedStakedTONABI, l1Provider);
const L2WSTONManager = new ethers.Contract(L2WSTONManagerAddress, L2WSTONManagerABI, l2Wallet);

L1WrappedStakedTON.on("Deposited", async (user, layer2, amount, stakingIndex, depositTime) => {
    console.log(`Deposited event received: user=${user}, layer2=${layer2}, amount=${amount}, stakingIndex=${stakingIndex}, depositTime=${depositTime}`);

    // Fetch data from L1 contract (replace with actual data fetching logic)
    try {
        const response = await axios.get(`https://api.l1contract.com/variable/${layer2}`);
        const variable = response.data.variable;

        // Send data to L2 contract
        const tx = await l2Contract.onDeposit(user, amount, stakingIndex, depositTime);
        await tx.wait();

        console.log(`Data relayed to L2 contract: user=${user}, layer2=${layer2}, amount=${amount}, stakingIndex=${stakingIndex}, depositTime=${depositTime}`);
    } catch (error) {
        console.error(`Error fetching or relaying data: ${error}`);
    }
});

console.log("Listening for Deposited events...");
