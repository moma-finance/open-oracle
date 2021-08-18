const HDWalletProvider = require("@truffle/hdwallet-provider");
require('dotenv').config();

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1', // Localhost (default: none)
      port: 8545, // Standard Ethereum port (default: none)
      network_id: '1',
      gasPrice: 50000000000,
      gas: 6721975, // Any network (default: none)
    },

    mainnet: {
      network_id: '1',
      provider: () => new HDWalletProvider(
        process.env.prikey,
        process.env.infura_url
      ),
      gasPrice: Number(process.env.GAS_PRICE),
      gas: 8000000,
      from: process.env.account,
      timeoutBlocks: 10,
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: '0.7.0', // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      //  optimizer: {
      //    enabled: false,
      //    runs: 200
      //  },
      //  evmVersion: "byzantium"
      // }
    },
  },
}
