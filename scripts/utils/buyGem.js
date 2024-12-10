const { ethers } = require("hardhat");
require('dotenv').config();
// command to run: "source .env"
// command to run: "npx hardhat run scripts/utils/buyGem.js --network thanos"

async function main() {
  const [deployer] = await ethers.getSigners();

  const marketPlaceProxyAddress = process.env.MARKETPLACE_PROXY;
  const l2wstonAddress = process.env.THANOS_WRAPPED_STAKED_TON;
  const gemfactoryProxyAddress = process.env.GEM_FACTORY_PROXY;

  // Thanos WSTON Contract ABI
  const wstonABI = [
    "function approve(address spender, uint256 value) public returns (bool)"
  ];

  // Create a contract instance for the TON token
  const L2Wston = new ethers.Contract(l2wstonAddress, wstonABI, deployer);

  const GemFactory = await ethers.getContractAt("GemFactory", gemfactoryProxyAddress);
  const MarketPlace = await ethers.getContractAt("MarketPlaceThanos", marketPlaceProxyAddress);
  const tonFeeRate = 10n;
  const rate_divider = 10000n;
  const price = 11n * 10n ** 27n
  const stakingIndex = 1012124297676993112994605823n;
  const divider = 1000000000000000000000000000n;
  const wstonPrice = price * stakingIndex / divider
  const totalPrice = (wstonPrice + ((wstonPrice * tonFeeRate)/rate_divider)) / (10n ** 9n);


  const gem = await GemFactory.getGem(223);
  //const price = gem.value;
  console.log({gem});


  await MarketPlace.buyGem(223, false, {
    gasLimit: 15000000,
    value: totalPrice
  })
  console.log("gem bought");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
