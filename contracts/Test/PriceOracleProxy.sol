pragma solidity ^0.7.0;

interface V1PriceOracleInterface {
    function assetPrices(address asset) external view returns (uint);
}

contract PriceOracleProxy {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /// @notice The v1 price oracle, which will continue to serve prices for v1 assets
    V1PriceOracleInterface public v1PriceOracle;

    /**
     * @param v1PriceOracle_ The address of v1PriceOracle
     */
    constructor(address v1PriceOracle_) {
        v1PriceOracle = V1PriceOracleInterface(v1PriceOracle_);
    }

    function getUnderlyingPrice(address mToken) public view returns (uint) {
        return v1PriceOracle.assetPrices(mToken);
    }
}
