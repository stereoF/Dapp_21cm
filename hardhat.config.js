require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()
// const { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } = require("hardhat/builtin-tasks/task-names");
// const path = require("path");

const { ALCHEMY_API_KEY, GOERLI_PRIVATE_KEY } = process.env;

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
      url: "http://172.28.160.1:7545",
      accounts: ["0x317240cc72c31504a78a01bda8ce3f466105406d5f19bb49f02ccecc649e39c2"]
    },
    // goerli: {
    //   url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
    //   accounts: [GOERLI_PRIVATE_KEY]
    // }
  }
};
