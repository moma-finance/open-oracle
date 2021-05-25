pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./MomaOracleConfig.sol";


contract MomaPriceOracleView is MomaOracleConfig {

    

    // TODO: Add Chainlink Type

    constructor(
        address guardian_,
        ChainlinkOracleInterface ethOracle_,
        address[] memory underlyings_,
        address[] memory mTokenOracles_, 
        uint256[] memory baseUnits_, 
        PriceSource[] memory priceSources_, 
        uint256[] memory fixedPrices_,
        string[] memory symbols_
    ) {
        // USDC、USDT 1e8
        guardian = guardian_;
        ethOracle = ethOracle_;
        for (uint i = 0; i < underlyings_.length; i++) {
            bytes32 symbolHash_ = keccak256(abi.encodePacked(symbols_[i]));
            tokenConfigs[underlyings_[i]] = TokenConfig({
                underlyingAssetOracle: ChainlinkOracleInterface(mTokenOracles_[i]),
                baseUnit: baseUnits_[i],
                priceSource: priceSources_[i],
                fixedPrice: fixedPrices_[i],
                symbolHash: symbolHash_
            });

            if (symbols[symbolHash_] == address(0)) {
                symbols[symbolHash_] = mTokenOracles_[i];
            }
        }
    }

    /**
     * @notice Get the underlying price of a listed mToken asset
     * @param mToken The mToken to get the underlying price
     * @return The underlying asset price mantissa (scaled by 1e18)
     */
    function assetPrices(address mToken) public view returns (uint) {
        MUnderlyingConfig memory targetPair = mUnderlyings[mToken];
        require(targetPair.isBuilt, "Not Support");
        if (targetPair.isETH) {
            (,int256 ethPrice,,,) = ethOracle.latestRoundData();
            uint usdPerEth = uint(ethPrice);
            require(usdPerEth > 0, "ETH price not set, cannot convert to dollars");
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
        require(targetOracle != ChainlinkOracleInterface(address(0)), "Not Supported");
        int256 _price;
        (roundId, _price, startedAt, updatedAt,) = targetOracle.latestRoundData();
        require(_price >= 0, "Invalid price");
        price = uint256(_price);
    }

    // price 1e8
    function price(string memory symbol_) public view returns(
        uint80 roundId,
        uint256 price,
        uint256 startedAt,
        uint256 updatedAt
    ) {
        ChainlinkOracleInterface targetOracle = ChainlinkOracleInterface(symbols[keccak256(abi.encodePacked(symbol_))]);
        require(targetOracle != ChainlinkOracleInterface(address(0)), "Not Supported");
        int256 _price;
        (roundId, _price, startedAt, updatedAt,) = targetOracle.latestRoundData();
        require(_price >= 0, "Invalid price");
        price = uint256(_price);
    }

    function priceInternal(TokenConfig memory tokenConfig) internal view returns (uint) {
        if (tokenConfig.priceSource == PriceSource.REPORTER) {
            ChainlinkOracleInterface targetOracle = tokenConfig.underlyingAssetOracle;
            require(targetOracle != ChainlinkOracleInterface(address(0)), "Not Supported");
            (,int256 price,,,) = targetOracle.latestRoundData();
            require(price >= 0, "Invalid price");
            uint assetPrice = uint(price);
            return assetPrice;
        }
        if (tokenConfig.priceSource == PriceSource.FIXED_USD) return tokenConfig.fixedPrice;
        if (tokenConfig.priceSource == PriceSource.FIXED_ETH) {
            (,int256 ethPrice,,,) = ethOracle.latestRoundData();
            uint usdPerEth = uint(ethPrice);
            require(usdPerEth > 0, "ETH price not set, cannot convert to dollars");
            return mul(usdPerEth, tokenConfig.fixedPrice) / ethBaseUnit;
        }
    }
}
