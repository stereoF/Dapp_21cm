require("@nomicfoundation/hardhat-toolbox");

const ALCHEMY_API_KEY = "L0xbJda_rOs6kPLMLxlgi0TOLx9wdGPu";

const GOERLI_PRIVATE_KEY = "f9d5d0c75dca4f7faaf156fbed0236e3afdfb8396860bcbad36806ba328069c4";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
  networks: {
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY]
    }
  }
};
