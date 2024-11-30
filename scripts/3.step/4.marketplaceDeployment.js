const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/3.step/4.marketplaceDeployment.js --network titan"

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    const MarketPlace = await ethers.getContractFactory("MarketPlaceThanos");
    
    // Deploy MarketPlace
    const marketPlace = await MarketPlace.deploy();
    await marketPlace.waitForDeployment(); // Ensure deployment is complete
    console.log("MarketPlaceThanos deployed to:", marketPlace.target);

    // Verify MarketPlace
    await run("verify:verify", {
      address: marketPlace.target,
      constructorArguments: [],
      contract:"src/L2/MarketPlaceThanos.sol:MarketPlaceThanos"
    });

    // Deploy MarketPlace Proxy
    const MarketPlaceProxy = await ethers.getContractFactory("MarketPlaceProxy");
    const marketPlaceProxy = await MarketPlaceProxy.deploy();
    await marketPlaceProxy.waitForDeployment(); // Ensure deployment is complete
    console.log("MarketPlaceProxy deployed to:", marketPlaceProxy.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    // Verify Treasury
    await run("verify:verify", {
      address: marketPlaceProxy.target,
      constructorArguments: [],
      contract:"src/L2/MarketPlaceProxy.sol:MarketPlaceProxy"
    });
    console.log("marketplaceProxy verified");

    // Set the first index to the GemFactory contract
    const upgradeTo = await marketPlaceProxy.upgradeTo(marketPlace.target);
    await upgradeTo.wait();
    console.log("marketPlaceProxy upgraded to marketPlace");

  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
