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
    // goerli: {
    //   url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
    //   accounts: [GOERLI_PRIVATE_KEY]
    // }
  }
};
