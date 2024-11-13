const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/1.step/2.L1WrappedStakedTONProxyVerification.js --network sepolia"

async function main() {
    const [deployer] = await ethers.getSigners();

    const l1wrappedtakedtonproxyAddress = process.env.L1_WRAPPED_STAKED_TON_PROXY;

    console.log("Deploying contracts with the account:", await deployer.getAddress());

    const balance = await ethers.provider.getBalance(await deployer.getAddress());
    console.log("Account balance:", ethers.formatEther(balance));

    // ------------------------ L1WRAPPEDSTAKEDTONPROXY verification ---------------------------------

    await run("verify:verify", {
        address: l1wrappedtakedtonproxyAddress,
        constructorArguments: [],
        contract: "src/L1/L1WrappedStakedTONProxy.sol:L1WrappedStakedTONProxy"
    });
    console.log("L1WrappedStakedTONProxy contract verified");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
