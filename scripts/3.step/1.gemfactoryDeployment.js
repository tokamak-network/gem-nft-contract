const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/3.step/1.gemfactoryDeployment.js --network titan"

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", await deployer.getAddress());

    const balance = await ethers.provider.getBalance(await deployer.getAddress());
    console.log("Account balance:", ethers.formatEther(balance));

    // ------------------------ GEMFACTORY INSTANCES ---------------------------------
    // Deploy ForgeLibrary
    const ForgeLibrary = await ethers.getContractFactory("ForgeLibrary");
    const forgeLibrary = await ForgeLibrary.deploy();
    await forgeLibrary.waitForDeployment();
    console.log("ForgeLibrary deployed to:", forgeLibrary.target);

    // Deploy MiningLibrary
    const MiningLibrary = await ethers.getContractFactory("MiningLibrary");
    const miningLibrary = await MiningLibrary.deploy();
    await miningLibrary.waitForDeployment();
    console.log("MiningLibrary deployed to:", miningLibrary.target);

    // Deploy GemLibrary
    const GemLibrary = await ethers.getContractFactory("GemLibrary");
    const gemLibrary = await GemLibrary.deploy();
    await gemLibrary.waitForDeployment();
    console.log("GemLibrary deployed to:", gemLibrary.target);

    // Instantiate the GemFactory
    const GemFactory = await ethers.getContractFactory("GemFactory");
    const gemFactory = await GemFactory.deploy();
    await gemFactory.waitForDeployment();
    console.log("GemFactory deployed to:", gemFactory.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    await run("verify:verify", {
        address: gemFactory.target,
        constructorArguments: [],
      });

    // Instantiate the GemFactoryForging
    const GemFactoryForging = await ethers.getContractFactory("GemFactoryForging");
    const gemFactoryForging = await GemFactoryForging.deploy();
    await gemFactoryForging.waitForDeployment();
    console.log("GemFactoryForging deployed to:", gemFactoryForging.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds
      
    await run("verify:verify", {
        address: gemFactoryForging.target,
        constructorArguments: [],
      });

    // Instantiate the GemFactoryMining
    const GemFactoryMining = await ethers.getContractFactory("GemFactoryMining");
    const gemFactoryMining = await GemFactoryMining.deploy();
    await gemFactoryMining.waitForDeployment();
    console.log("GemFactoryMining deployed to:", gemFactoryMining.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    await run("verify:verify", {
        address: gemFactoryMining.target,
        constructorArguments: [],
      });

    // ------------------------ GEMFACTORY PROXY ---------------------------------

    const GemFactoryProxy = await ethers.getContractFactory("GemFactoryProxy");
    const gemFactoryProxy = await GemFactoryProxy.deploy();
    await gemFactoryProxy.waitForDeployment();
    console.log("GemFactoryProxy deployed to:", gemFactoryProxy.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    // verifying the contract
    await run("verify:verify", {
        address: gemFactoryProxy.target,
        constructorArguments: [],
        contract:"src/L2/GemFactoryProxy.sol:GemFactoryProxy"
      });

    // Set the first index to the GemFactory contract
    const upgradeTo = await gemFactoryProxy.upgradeTo(gemFactory.target);
    await upgradeTo.wait();
    console.log("GemFactoryProxy upgraded to GemFactory");

    // Set the second index to the GemFactoryForging contract
    const setImplementation = await gemFactoryProxy.setImplementation2(gemFactoryForging.target, 1, true);
    await setImplementation.wait();
    console.log("GemFactoryProxy implementation set to GemFactoryForging");

    // Set the third index to the GemFactoryMining contract
    const setImplementation2 = await gemFactoryProxy.setImplementation2(gemFactoryMining.target, 2, true);
    await setImplementation2.wait();
    console.log("GemFactoryProxy implementation set to GemFactoryMining");

    // ------------------------ FUNCTION SELECTORS ---------------------------------

    // Compute the function selector for GemFactoryForging
    const forgeTokensSelector = ethers.keccak256(ethers.toUtf8Bytes("forgeTokens(uint256[],uint8,uint8[2])")).substring(0, 10);
    const forgingSelectors = [forgeTokensSelector];

    // Map the forgeTokens function to the GemFactoryForging implementation
    const setForgingSelectors = await gemFactoryProxy.setSelectorImplementations2(forgingSelectors, gemFactoryForging.target);
    await setForgingSelectors.wait();
    console.log("Mapped forgeTokens function to GemFactoryForging");

    // Compute the function selectors for GemFactoryMining
    const startMiningSelector = ethers.keccak256(ethers.toUtf8Bytes("startMiningGEM(uint256)")).substring(0, 10);
    const cancelMiningSelector = ethers.keccak256(ethers.toUtf8Bytes("cancelMining(uint256)")).substring(0, 10);
    const pickMinedGEMSelector = ethers.keccak256(ethers.toUtf8Bytes("pickMinedGEM(uint256)")).substring(0, 10);
    const drbInitializeSelector = ethers.keccak256(ethers.toUtf8Bytes("DRBInitialize(address)")).substring(0, 10);
    const rawFulfillRandomWordsSelector = ethers.keccak256(ethers.toUtf8Bytes("rawFulfillRandomWords(uint256,uint256)")).substring(0, 10);

    const miningSelectors = [
        startMiningSelector,
        cancelMiningSelector,
        pickMinedGEMSelector,
        drbInitializeSelector,
        rawFulfillRandomWordsSelector
    ];

    // Map the mining functions to the GemFactoryMining implementation
    const setMiningSelectors = await gemFactoryProxy.setSelectorImplementations2(miningSelectors, gemFactoryMining.target);
    await setMiningSelectors.wait();
    console.log("Mapped mining functions to GemFactoryMining");

    // Debugging: Verify the mapping
    const forgeTokensImplementation = await gemFactoryProxy.getSelectorImplementation2(forgeTokensSelector);
    if (forgeTokensImplementation !== gemFactoryForging.target) {
        throw new Error("Selector not mapped to GemFactoryForging");
    }

    const startMiningImpl = await gemFactoryProxy.getSelectorImplementation2(startMiningSelector);
    if (startMiningImpl !== gemFactoryMining.target) {
        throw new Error("Selector not mapped to GemFactoryMining");
    }

    console.log("Function selectors verified successfully");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
