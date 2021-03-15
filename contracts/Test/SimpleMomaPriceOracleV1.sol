pragma solidity ^0.7.0;

interface ChainlinkOracleInterface {
    function latestRoundData() external view returns (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IMToken {
    function underlying() external view returns (address);
}

contract SimpleMomaPriceOracleV1 {

    address public guardian;

    // TODO: Add Chainlink Type
    enum PriceSource {
        FIXED_ETH, /// implies the fixedPrice is a constant multiple of the ETH price (which varies)
        FIXED_USD, /// implies the fixedPrice is a constant multiple of the USD price (which is 1)
        REPORTER   /// implies the price is set by the reporter
    }

    struct TokenConfig {
        ChainlinkOracleInterface underlyingAssetOracle;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
    }

    struct MUnderlyingConfig {
        address underlying;
        bool isETH;
        bool isBuilt;
    }

    mapping(address => MUnderlyingConfig) public mUnderlyings;
    mapping(address => TokenConfig) public tokenConfigs;

    ChainlinkOracleInterface public ethOracle;
    uint public constant ethBaseUnit = 1e18;
    uint public constant ethFixedPrice = 1e18;

    constructor(
        address guardian_,
        ChainlinkOracleInterface ethOracle_,
        address[] memory mTokens_,
        address[] memory underlyings_,
        bool[] memory isETHs_,
        address[] memory mTokenOracles_, 
        uint256[] memory baseUnits_, 
        PriceSource[] memory priceSources_, 
        uint256[] memory fixedPrices_
    ) {
        // USDC、USDT 1e8
        guardian = guardian_;
        ethOracle = ethOracle_;
        for (uint i = 0; i < mTokens_.length; i++) {
            tokenConfigs[underlyings_[i]] = TokenConfig({
                underlyingAssetOracle: ChainlinkOracleInterface(mTokenOracles_[i]),
                baseUnit: baseUnits_[i],
                priceSource: priceSources_[i],
                fixedPrice: fixedPrices_[i]
            });
            mUnderlyings[mTokens_[i]] = MUnderlyingConfig({underlying: underlyings_[i], 
                isETH: isETHs_[i], 
                isBuilt: true
            });
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
    function getPrice(address underlyingAsset) public view returns(uint) {
        TokenConfig memory targetTokenConfig = tokenConfigs[underlyingAsset];
        ChainlinkOracleInterface targetOracle = targetTokenConfig.underlyingAssetOracle;
        require(targetOracle != ChainlinkOracleInterface(address(0)), "Not Supported");
        (,int256 price,,,) = targetOracle.latestRoundData();
        require(price >= 0, "Invalid price");
        uint assetPrice = uint(price);
        return assetPrice;
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

    function setNewOracle(
            address oracle_,
            address underlying_,
            uint256 baseUnit_, 
            PriceSource priceSource_, 
            uint256 fixedPrice_
        ) public {
        require(msg.sender == guardian, "Only guardian may add new price oracle");
        tokenConfigs[underlying_] = TokenConfig({
                underlyingAssetOracle: ChainlinkOracleInterface(oracle_),
                baseUnit: baseUnit_,
                priceSource: priceSource_,
                fixedPrice: fixedPrice_
        });
    }

    function setNewMUnderlying(
            IMToken mToken,
            bool isETH_
        ) public {
        MUnderlyingConfig storage newMUnderlyingPair = mUnderlyings[address(mToken)];
        if (isETH_) {
            newMUnderlyingPair.isBuilt = true;
            newMUnderlyingPair.isETH = true;
        } else {
            address targetUnderlying = mToken.underlying();
            TokenConfig memory config = tokenConfigs[targetUnderlying];
            require(config.underlyingAssetOracle != ChainlinkOracleInterface(address(0)), "Not Supported Underlying");
            newMUnderlyingPair.underlying = targetUnderlying;
            newMUnderlyingPair.isBuilt = true;
        }
    }


    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}
