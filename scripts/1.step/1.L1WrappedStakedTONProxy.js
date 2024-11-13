const { ethers, run } = require("hardhat");
require('dotenv').config();

// command to run: "npx hardhat run scripts/1.step/1.L1WrappedStakedTONProxy.js --network sepolia"

async function main() {
    const [deployer] = await ethers.getSigners();

    const depositManagerAddress = process.env.DEPOSIT_MANAGER;
    const seigManagerAddress = process.env.SEIG_MANAGER;
    const layer2Address = process.env.LAYER_2;
    const l1wton = process.env.L1_WTON;
    const l1ton = process.env.L1_TON;

    console.log("Deploying contracts with the account:", await deployer.getAddress());

    const balance = await ethers.provider.getBalance(await deployer.getAddress());
    console.log("Account balance:", ethers.formatEther(balance));

    // ------------------------ L1WRAPPEDSTAKEDTONFACTORY INSTANCES ---------------------------------

    // Instantiate the L1WrappedStakedTONFactory
    const L1WrappedStakedTONFactory = await ethers.getContractFactory("L1WrappedStakedTONFactory");
    const l1WrappedStakedTONfactory = await L1WrappedStakedTONFactory.deploy();
    await l1WrappedStakedTONfactory.waitForDeployment();
    console.log("l1WrappedStakedTONfactory deployed to:", l1WrappedStakedTONfactory.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    await run("verify:verify", {
        address: l1WrappedStakedTONfactory.target,
        constructorArguments: [],
    });

    // Instantiate the L1WrappedStakedTON
    const L1WrappedStakedTON = await ethers.getContractFactory("L1WrappedStakedTON");
    const l1WrappedStakedTON = await L1WrappedStakedTON.deploy();
    await l1WrappedStakedTON.waitForDeployment();
    console.log("l1WrappedStakedTON deployed to:", l1WrappedStakedTON.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    await run("verify:verify", {
        address: l1WrappedStakedTON.target,
        constructorArguments: [],
    });

    // ------------------------ L1WRAPPEDSTAKEDTONFACTORY PROXY ---------------------------------

    const L1WrappedStakedTONFactoryProxy = await ethers.getContractFactory("L1WrappedStakedTONFactoryProxy");
    const l1WrappedStakedTONFactoryProxy = await L1WrappedStakedTONFactoryProxy.deploy();
    await l1WrappedStakedTONFactoryProxy.waitForDeployment();
    console.log("l1WrappedStakedTONFactoryProxy deployed to:", l1WrappedStakedTONFactoryProxy.target);

    await new Promise(resolve => setTimeout(resolve, 30000)); // Wait for 30 seconds

    // verifying the contract
    await run("verify:verify", {
        address: l1WrappedStakedTONFactoryProxy.target,
        constructorArguments: [],
        contract: "src/L1/L1WrappedStakedTONFactoryProxy.sol:L1WrappedStakedTONFactoryProxy"
      });

    // Set the first index to the GemFactory contract
    const upgradeTo = await l1WrappedStakedTONFactoryProxy.upgradeTo(l1WrappedStakedTONfactory.target);
    await upgradeTo.wait();
    console.log("l1WrappedStakedTONFactoryProxy upgraded to l1WrappedStakedTONfactory");

    // initializing L1WrappedStakedTONFactory
    const l1WrappedStakedTONFactoryAttached = L1WrappedStakedTONFactory.attach(l1WrappedStakedTONFactoryProxy.target);

    const initialize = await l1WrappedStakedTONFactoryAttached.initialize(
        l1wton,
        l1ton
    );
    await initialize.wait();
    console.log("L1WrappedStakedTONFactoryProxy initialized")

    // setting WSTON implementation to the factory
    const setImpl = await l1WrappedStakedTONFactoryAttached.setWstonImplementation(l1WrappedStakedTON.target);
    await setImpl.wait();
    console.log("implementation set to L1WrappedStakedTON");

    // ------------------------ L1WRAPPEDSTAKEDTON TITAN DEPLOYMENT ---------------------------------
    
    await l1WrappedStakedTONFactoryAttached.createWSTONToken(
        layer2Address,
        depositManagerAddress,
        seigManagerAddress,
        BigInt(100 * 10 ** 27), // 100 WSTON minimum withdrawal amount
        BigInt(10), // 10 maximum number of withdrawals
        "Titan Wston",
        "WSTON"
    );
    console.log("New WSTON Token created");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
