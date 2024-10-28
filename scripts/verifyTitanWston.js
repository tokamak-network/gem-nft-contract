const { ethers, run } = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    const titanWstonAddress = process.env.TITAN_WRAPPED_STAKED_TON;
    const addressL2Bridge = process.env.L2_BRIDGE;
    const l1token = process.env.L1_WRAPPED_STAKED_TON;

    // Verify titan wston
    await run("verify:verify", {
        address: titanWstonAddress,
        constructorArguments: [
            addressL2Bridge,
            l1token,
            "Titan Wston",
            "TITANWSTON"
        ],
    });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
