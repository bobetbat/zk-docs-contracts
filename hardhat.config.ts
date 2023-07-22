import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

require("dotenv").config();

const {WALLET_PRIVATE_KEY, ALCHEMY_API_KEY} = process.env;

const networks = {
  sepolia: {
    url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
    accounts: [WALLET_PRIVATE_KEY as string],
  }
};

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      }
    },
  },
  networks: networks,
};

export default config;
