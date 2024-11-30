const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/3.step/6.wstonSwapPoolDeployment.js --network titan"

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    // Deploy WstonSwapPool
    const WstonSwapPool = await ethers.getContractFactory("WstonSwapPoolThanos");
    const wstonSwapPool = await WstonSwapPool.deploy();
    await wstonSwapPool.waitForDeployment(); // Ensure deployment is complete
    console.log("WstonSwapPoolThanos deployed to:", wstonSwapPool.target);

    // Verify WstonSwapPool
    await run("verify:verify", {
      address: wstonSwapPool.target,
      constructorArguments: [],
    });

    // Deploy WstonSwapPoolProxy
    const WstonSwapPoolProxy = await ethers.getContractFactory("WstonSwapPoolProxy");
    const wstonSwapPoolProxy = await WstonSwapPoolProxy.deploy();
    await wstonSwapPoolProxy.waitForDeployment(); // Ensure deployment is complete
    console.log("wstonSwapPoolProxy deployed to:", wstonSwapPoolProxy.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    // Verify WstonSwapPoolProxy
    await run("verify:verify", {
      address: wstonSwapPoolProxy.target,
      constructorArguments: [],
      contract:"src/L2/WstonSwapPoolProxy.sol:WstonSwapPoolProxy"
    });
    console.log("WstonSwapPoolProxy verified");

    // Set the first index to the GemFactory contract
    const upgradeTo = await wstonSwapPoolProxy.upgradeTo(wstonSwapPool.target);
    await upgradeTo.wait();
    console.log("wstonSwapPoolProxy upgraded to wstonSwapPool");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
