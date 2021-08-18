const { oracle_configs } = require('./oracle_config');
// ============ Contracts ============

// deployed and init

const MomaPriceOracleView = artifacts.require("MomaPriceOracleView");


// ============ Main Migration ============

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployOracle(deployer, network, accounts),
  ]);
};

module.exports = migration;

// ============ Deploy Functions ============

async function deployOracle(deployer, network, accounts) {

  const guardian_ = "0x376fe4D01F14Ed16dDDA449f8dD331e2970B33D6";
  const ethOracle_ = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";
  const momaFactory_ = "0x16287C74672Bb45dCB0a282243ca8514Bc9d1AB1";

  let underlyings_ = [];
  let oracles_ = [];
  let baseUnits_ = [];
  let priceSources_ = [];
  let fixedPrices_ = [];
  let symbols_ = [];

  for (const { symbol, tokenAddr, oracleAddr, baseUnit, priceSource, fixedPrice } of oracle_configs) {
    symbols_.push(symbol);
    underlyings_.push(tokenAddr);
    oracles_.push(oracleAddr);
    baseUnits_.push(baseUnit);
    priceSources_.push(priceSource);
    fixedPrices_.push(fixedPrice);
  }

  await deployer.deploy(MomaPriceOracleView, guardian_, ethOracle_, underlyings_, oracles_, baseUnits_, priceSources_, fixedPrices_, symbols_, momaFactory_);
}
