const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/3.step/4.marketplaceDeployment.js --network titan"

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    const marketPlaceProxyAddress = process.env.MARKETPLACE_PROXY;
    const marketPlaceProxy = await ethers.getContractAt("MarketPlaceProxy", marketPlaceProxyAddress);

    const MarketPlace = await ethers.getContractFactory("MarketPlaceThanos");
    
    // Deploy MarketPlace
    const marketPlace = await MarketPlace.deploy();
    await marketPlace.waitForDeployment(); // Ensure deployment is complete
    console.log("MarketPlaceThanos deployed to:", marketPlace.target);

    // Verify MarketPlace
    await run("verify:verify", {
      address: marketPlace.target,
      constructorArguments: [],
      contract:"src/L2/MarketPlace.sol:MarketPlace"
    });


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
