pragma solidity ^0.5.16;

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

    mapping(address => ChainlinkOracleInterface) public prices;

    /**
     * @param guardian_ The address of the guardian, which may set the new price oracle
     * @param mToken_ The address of mToken list
     * @param mTokenOracle_ The address of mToken underlying token's chainlink oracle
     */
    constructor(address guardian_, address[] memory mToken_, address[] memory mTokenOracle_) public {
        guardian = guardian_;
        for (uint i = 0; i < mToken_.length; i++) {
            prices[mToken_[i]] = ChainlinkOracleInterface(mTokenOracle_[i]);
        }
    }

    /**
     * @notice Get the underlying price of a listed mToken asset
     * @param mToken The mToken to get the underlying price
     * @return The underlying asset price mantissa (scaled by 1e18)
     */
    function assetPrices(address mToken) public view returns (uint) {
        ChainlinkOracleInterface targetOracle = prices[mToken];
        require(targetOracle != ChainlinkOracleInterface(address(0)), "Not Supported");
        (,int256 price,,,) = targetOracle.latestRoundData();
        require(price >= 0, "Invalid price");
        return uint(price);
    }

    /**
     * @notice Set the new price oracle 
     * @param mTokenAddress_  The mToken to get the underlying price
     * @param newOracle_ The newOracle
     */
    function setNewOracle(address mTokenAddress_, address newOracle_) public {
        require(msg.sender == guardian, "Only guardian may add new price oracle");
        require(newOracle_ == address(0), "New price oracle is invalid");
        prices[mTokenAddress_] = ChainlinkOracleInterface(newOracle_);
    }
}
