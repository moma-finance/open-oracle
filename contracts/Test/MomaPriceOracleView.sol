pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;
import "./MomaOracleConfig.sol";


contract MomaPriceOracleView is MomaOracleConfig {

    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;
    // TODO: Add Chainlink Type

    constructor(
        address guardian_,
        ChainlinkOracleInterface ethOracle_,
        address[] memory underlyings_,
        address[] memory oracles_, 
        uint256[] memory baseUnits_, 
        PriceSource[] memory priceSources_, 
        uint256[] memory fixedPrices_,
        string[] memory symbols_,
        IMomaFactory momaFactory_
    ) {
        // USDC、USDT 1e8
        require(guardian_ != address(0), "guardian_ is a zero address");
        require(address(ethOracle_) != address(0), "ethOracle_ is a zero address");
        require(address(momaFactory_) != address(0), "momaFactory_ is a zero address");
        
        guardian = guardian_;
        ethOracle = ethOracle_;
        momaFactory = momaFactory_;
        for (uint i = 0; i < underlyings_.length; i++) {
            bytes32 symbolHash_ = keccak256(abi.encodePacked(symbols_[i]));
            tokenConfigs[underlyings_[i]] = TokenConfig({
                underlyingAssetOracle: ChainlinkOracleInterface(oracles_[i]),
                baseUnit: baseUnits_[i],
                priceSource: priceSources_[i],
                fixedPrice: fixedPrices_[i],
                symbolHash: symbolHash_
            });

            if (symbols[symbolHash_] == address(0)) {
                symbols[symbolHash_] = oracles_[i];
            }
        }
    }

    /**
     * @notice Get the underlying price of a listed mToken asset
     * @param mToken The mToken to get the underlying price
     * @return Price denominated in USD, with 18 decimals, for the given mToken address
     */
    function getUnderlyingPrice(address mToken) public view returns (uint) {
        MUnderlyingConfig memory targetPair = mUnderlyings[mToken];
        require(targetPair.isBuilt, "Not Support");
        if (targetPair.isETH) {
            (,int256 ethPrice,,,) = ethOracle.latestRoundData();
            require(ethPrice > 0, "ETH price not set, cannot convert to dollars");
            uint usdPerEth = uint(ethPrice);
            uint targetPrice = mul(usdPerEth, ethFixedPrice) / ethBaseUnit;
            return (mul(1e28, targetPrice)) / ethBaseUnit;
        }
        TokenConfig memory tokenConfig = tokenConfigs[targetPair.underlying];
        return (mul(1e28, priceInternal(tokenConfig)) / tokenConfig.baseUnit);
    }

    // price 1e8
    function getPrice(address underlyingAsset) public view returns(
        uint80 roundId,
        uint256 price,
        uint256 startedAt,
        uint256 updatedAt
    ) {
        TokenConfig storage targetTokenConfig = tokenConfigs[underlyingAsset];
        ChainlinkOracleInterface targetOracle = targetTokenConfig.underlyingAssetOracle;
        (roundId, price, startedAt, updatedAt) = getChainlinkPrice(targetOracle);
    }

    // price 1e8
    function price(string memory symbol_) public view returns(
        uint80 roundId,
        uint256 price,
        uint256 startedAt,
        uint256 updatedAt
    ) {
        ChainlinkOracleInterface targetOracle = ChainlinkOracleInterface(symbols[keccak256(abi.encodePacked(symbol_))]);
        (roundId, price, startedAt, updatedAt) = getChainlinkPrice(targetOracle);
    }

    function getChainlinkPrice(ChainlinkOracleInterface targetOracle) internal view returns(
        uint80 roundId,
        uint256 price,
        uint256 startedAt,
        uint256 updatedAt
    ) {
        require(targetOracle != ChainlinkOracleInterface(address(0)), "Not Supported");
        int256 _price;
        (roundId, _price, startedAt, updatedAt,) = targetOracle.latestRoundData();
        require(_price >= 0, "Invalid price");
        price = uint256(_price);
    }

    function priceInternal(TokenConfig memory tokenConfig) internal view returns (uint) {
        if (tokenConfig.priceSource == PriceSource.REPORTER) {
            ChainlinkOracleInterface targetOracle = tokenConfig.underlyingAssetOracle;
            if (targetOracle == ChainlinkOracleInterface(address(0))) {
                return uint(0);
            }
            (,int256 price,,,) = targetOracle.latestRoundData();
            require(price >= 0, "Invalid price");
            uint assetPrice = uint(price);
            return assetPrice;
        }
        if (tokenConfig.priceSource == PriceSource.FIXED_USD) return tokenConfig.fixedPrice;
        if (tokenConfig.priceSource == PriceSource.FIXED_ETH) {
            (,int256 ethPrice,,,) = ethOracle.latestRoundData();
            require(ethPrice > 0, "ETH price not set, cannot convert to dollars");
            uint usdPerEth = uint(ethPrice);
            return mul(usdPerEth, tokenConfig.fixedPrice) / ethBaseUnit;
        }
    }
    
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}
