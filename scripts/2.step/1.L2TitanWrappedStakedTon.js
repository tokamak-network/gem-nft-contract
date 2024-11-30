const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/2.step/1.L2TitanWrappedStakedTon.js --network thanos"

async function main() {
    const [deployer] = await ethers.getSigners();

    const l2Bridge = process.env.L2_BRIDGE;
    const l1Token = process.env.L1_WRAPPED_STAKED_TON_PROXY;

    console.log("Deploying contracts with the account:", await deployer.getAddress());

    const balance = await ethers.provider.getBalance(await deployer.getAddress());
    console.log("Account balance:", ethers.formatEther(balance));

    // ------------------------ L2TitanWrappedStakedTon Deployment ---------------------------------
    
    // Instantiate the L1WrappedStakedTONFactory
    const TitanWston = await ethers.getContractFactory("L2StandardERC20");
    const titanWston = await TitanWston.deploy(
        l2Bridge,
        l1Token,
        "Thanos Wston",
        "TWSTON"
    );
    await titanWston.waitForDeployment();
    console.log("L2 Thanos Wston deployed to:", titanWston.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    await run("verify:verify", {
        address: titanWston.target,
        constructorArguments: [
            l2Bridge,
            l1Token,
            "Thanos Wston",
            "TWSTON"
        ],
        contract: "src/L2/L2StandardERC20.sol:L2StandardERC20"
    });

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
