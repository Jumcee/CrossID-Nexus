// require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("dotenv").config();
const { RPC_URL, PRIVATE_KEY } = process.env

module.exports = {
  solidity: "0.8.24",
  networks: {
    arbitrumSepolia: {
      url: process.env.RPC_URL,
      chainId: 421614,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};