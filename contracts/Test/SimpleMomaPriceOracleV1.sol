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

contract SimpleMomaPriceOracleV1 {

    address public guardian;

    enum PriceSource {
        FIXED_ETH, /// implies the fixedPrice is a constant multiple of the ETH price (which varies)
        FIXED_USD, /// implies the fixedPrice is a constant multiple of the USD price (which is 1)
        REPORTER   /// implies the price is set by the reporter
    }

    /// @dev Describe how the USD price should be determined for an asset.
    ///  There should be 1 TokenConfig object for each supported asset, passed in the constructor.
    struct TokenConfig {
        ChainlinkOracleInterface underlyingAssetOracle;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
    }

    mapping(address => ChainlinkOracleInterface) public prices;
    mapping(address => TokenConfig) public tokenConfigs;
    ChainlinkOracleInterface public ethOracle;
    uint public constant ethBaseUnit = 1e18;
    /**
     * @param guardian_ The address of the guardian, which may set the new price oracle
     * @param mToken_ The address of mToken list
     * @param mTokenOracle_ The address of mToken underlying token's chainlink oracle
     */
    constructor(
            address guardian_,
            ChainlinkOracleInterface ethOracle_,
            address[] memory mToken_, 
            address[] memory mTokenOracle_, 
            uint256[] memory baseUnits_, 
            PriceSource[] memory priceSources_, 
            uint256[] memory fixedPrices_
        ) public {
        guardian = guardian_;
        ethOracle = ethOracle_;
        for (uint i = 0; i < mToken_.length; i++) {
            tokenConfigs[mToken_[i]] = TokenConfig({
                underlyingAssetOracle: ChainlinkOracleInterface(mTokenOracle_[i]),
                baseUnit: baseUnits_[i],
                priceSource: priceSources_[i],
                fixedPrice: fixedPrices_[i]
            });
        }
    }

    /**
     * @notice Get the underlying price of a listed mToken asset
     * @param mToken The mToken to get the underlying price
     * @return The underlying asset price mantissa (scaled by 1e18)
     */
    function assetPrices(address mToken) public view returns (uint) {
        TokenConfig memory tokenConfig = tokenConfigs[mToken];
        // USDC、USDT 1e8
        return (mul(1e28, priceInternal(tokenConfig)) / tokenConfig.baseUnit);
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
            address mToken_, 
            address mTokenOracle_, 
            uint256 baseUnit_, 
            PriceSource priceSource_, 
            uint256 fixedPrice_
        ) public {
        require(msg.sender == guardian, "Only guardian may add new price oracle");
        tokenConfigs[mToken_] = TokenConfig({
                underlyingAssetOracle: ChainlinkOracleInterface(mTokenOracle_),
                baseUnit: baseUnit_,
                priceSource: priceSource_,
                fixedPrice: fixedPrice_
        });
    }


    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}
