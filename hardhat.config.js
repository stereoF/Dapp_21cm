require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()
// require("@nomiclabs/hardhat-ethers");
// require("@nomiclabs/hardhat-etherscan");
// const { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } = require("hardhat/builtin-tasks/task-names");
// const path = require("path");

const { MUMBAI_PRIVATE_KEY, MUMBAI_POLYGONSCAN_API_KEY, PRIVATE_KEY, POLYGON_URL } = process.env;

// subtask(
//   TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS,
//   async (_, { config }, runSuper) => {
//     const paths = await runSuper();

//     return paths
//       .filter(solidityFilePath => {
//         const relativePath = path.relative(config.paths.sources, solidityFilePath)

//         // return relativePath !== "PrePrintTrack.sol";
//         return ["PrePrintTrack.sol", "DeSciRoleModel.sol"].includes(relativePath)
//       })
//   }
// );

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  // defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337 // We set 1337 to make interacting with MetaMask simpler
    },
    ganache: {
      url: "http://172.27.192.1:7545",
      accounts: ["0x93030c2db7ee1564b43693f99776a27112059dcd9c5cec8052f13444c991e0e7"]
    },
    polygon_mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [MUMBAI_PRIVATE_KEY]
    },
    polygon: {
      url: POLYGON_URL,
      accounts: [PRIVATE_KEY]
    },
    bnb_testnet: {
      url: "https://bsc-testnet-dataseed.bnbchain.org",
      accounts: [PRIVATE_KEY]
    },
    // goerli: {
    //   url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
    //   accounts: [GOERLI_PRIVATE_KEY]
    // }
  },
  etherscan: {
    apiKey: MUMBAI_POLYGONSCAN_API_KEY
  },
};
