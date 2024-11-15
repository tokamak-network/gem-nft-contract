const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/3.step/4.marketplaceDeployment.js --network titan"

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", ethers.formatEther(balance));

    const MarketPlace = await ethers.getContractFactory("MarketPlace");
    
    // Deploy MarketPlace
    const marketPlace = await MarketPlace.deploy();
    await marketPlace.waitForDeployment(); // Ensure deployment is complete
    console.log("MarketPlace deployed to:", marketPlace.target);

    // Verify MarketPlace
    await run("verify:verify", {
      address: marketPlace.target,
      constructorArguments: [],
      contract:"src/L2/MarketPlace.sol:MarketPlace"
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
    console.log("MarketPlaceProxy verified");

    // Set the first index to the GemFactory contract
    const upgradeTo = await marketPlaceProxy.upgradeTo(marketPlace.target);
    await upgradeTo.wait();
    console.log("marketPlaceProxy upgraded to marketPlace");

    // -------------------------- MARKETPLACEPROXY INITIALIZATION -------------------------------

    // Attach the MarketPlace interface to the MarketPlaceProxy contract address
    const marketPlaceProxyAsMarketPlace = MarketPlace.attach(marketPlaceProxy.target);

    // Call the MarketPlace initialize function
    const tx3 = await marketPlaceProxyAsMarketPlace.initialize(
        process.env.TREASURY_PROXY,
        process.env.GEM_FACTORY_PROXY,
        BigInt(10), // ton fee rate = 10
        process.env.TITAN_WRAPPED_STAKED_TON, // l2wston
        process.env.TON_ADDRESS, // l2ton
    );
    await tx3.wait();
    console.log("MarketPlaceProxy initialized");

    const treasuryAddress = process.env.TREASURY;
    const treasuryProxyAddress = process.env.TREASURY_PROXY;
    const gemFactoryAddress = process.env.GEM_FACTORY;
    const gemFactoryProxyAddress = process.env.GEM_FACTORY_PROXY;
    const GemFactory = await ethers.getContractAt("GemFactory", gemFactoryAddress);
    const Treasury = await ethers.getContractAt("Treasury", treasuryAddress);
    
    // Attach the GemFactory interface to the GemFactoryProxy address
    const gemFactoryProxyAsGemFactory = GemFactory.attach(gemFactoryProxyAddress);
    // Attach the Treasury interface to the TreasuryProxy contract address
    const treasuryProxyAsTreasury = Treasury.attach(treasuryProxyAddress);
    
    // Set MarketPlace Address in GemFactory
    const setMarketPlaceAddressinGemFactory = await gemFactoryProxyAsGemFactory.setMarketPlaceAddress(marketPlaceProxy.target);
    setMarketPlaceAddressinGemFactory.wait();
    console.log("MarketPlaceProxy address set in GemFactoryProxy");

    await treasuryProxyAsTreasury.setMarketPlace(marketPlaceProxy.target);
    console.log("MarketPlaceProxy address set in Treasury");
  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
