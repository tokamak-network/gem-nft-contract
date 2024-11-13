require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require('hardhat-contract-sizer');
require('dotenv').config();

module.exports = {
  solidity: {
    version: "0.8.25",
    settings: {
      optimizer: {
        enabled: true,
        runs: 20,
      },
      viaIR: true,
    },
  },
  networks: {
    hardhat: {},
    titan: {
      url: process.env.TITAN_SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 11155111, // Sepolia testnet chain ID
    }
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY,
      titan_sepolia: "abcd",
      bscTestnet: "abcd",
    },
    customChains: [
      {
        network: "titan_sepolia",
        chainId: 55007,
        urls: {
            apiURL: "https://explorer.titan-sepolia.tokamak.network/api",
            browserURL: "https://explorer.titan-sepolia.tokamak.network/",
        },
    }
    ]
  }
};
