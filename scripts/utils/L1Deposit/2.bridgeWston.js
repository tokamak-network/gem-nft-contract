const { ethers } = require("hardhat");
require('dotenv').config();

// npx hardhat run scripts/utils/L1Deposit/2.bridgeWston.js --network sepolia

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Minting GEMs with the account:", deployer.address);
    const l1wstonProxyAddress = process.env.L1_WRAPPED_STAKED_TON_PROXY;
    const l1bridge = process.env.THANOS_L1_BRIDGE;
    const remoteToken = process.env.THANOS_WRAPPED_STAKED_TON;

    // Get contract instance
    const Wston = await ethers.getContractAt("L1WrappedStakedTON", l1wstonProxyAddress, deployer);

    // L1 Bridge Contract ABI
    const l1BridgeABI = [
        "function bridgeERC20(address _localToken, address _remoteToken, uint256 _amount, uint32 _minGasLimit, bytes calldata _extraData) public"
    ];

    // Create a contract instance for the L1 Bridge
    const l1BridgeContract = new ethers.Contract(l1bridge, l1BridgeABI, deployer);

    // Define the amount to deposit (in WSTON with 27 decimals)
    const wstonAmount = ethers.parseUnits('40628', 27); 

    try {
        // Call the approve function
        console.log("Approving WSTON...");
        const tx = await Wston.approve(l1bridge, wstonAmount);
        console.log('Approval transaction sent:', tx.hash);

        // Wait for the transaction to be mined
        const receipt = await tx.wait();
        console.log('Approval transaction mined:', receipt.transactionHash);

        console.log("Bridging WSTON...");
        // Call the bridge function
        const tx1 = await l1BridgeContract.bridgeERC20(l1wstonProxyAddress, remoteToken, wstonAmount, 210000, "0x", {
            gasLimit: 15000000 
        });
        console.log('Transaction sent:', tx1.hash);

        // Wait for the transaction to be confirmed
        const receipt1 = await tx1.wait();
        console.log("Transaction successful, receipt:", receipt1);
    } catch (error) {
        console.error('Error bridging WSTON:', error);
    }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error:", error);
    process.exit(1);
  });
