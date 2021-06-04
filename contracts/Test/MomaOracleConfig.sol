pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

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

interface IMomaFactory {
    function isCodeSame(address a, address b) external view returns (bool);
    function mErc20() external view returns (address);
    function mEther() external view returns (address);
}

contract MomaOracleConfig {
    address public guardian;

    IMomaFactory public momaFactory;

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
        bytes32 symbolHash;
    }

    struct MUnderlyingConfig {
        address underlying;
        bool isETH;
        bool isBuilt;
    }

    mapping(address => MUnderlyingConfig) public mUnderlyings;
    mapping(address => TokenConfig) public tokenConfigs;
    mapping(bytes32 => address) public symbols;

    ChainlinkOracleInterface public ethOracle;
    uint public constant ethBaseUnit = 1e18;
    uint public constant ethFixedPrice = 1e18;

    function setNewGuardian(address guardian_) public {
        require(msg.sender == guardian, "Only guardian");
        guardian = guardian_;
    }
    
    function setNewOracle(
        address oracle_,
        address underlying_,
        uint256 baseUnit_, 
        PriceSource priceSource_, 
        uint256 fixedPrice_,
        string memory symbol_
    ) public {
        require(msg.sender == guardian, "Only guardian may add new price oracle");
        bytes32 symbolHash_ = keccak256(abi.encodePacked(symbol_));
        tokenConfigs[underlying_] = TokenConfig({
                underlyingAssetOracle: ChainlinkOracleInterface(oracle_),
                baseUnit: baseUnit_,
                priceSource: priceSource_,
                fixedPrice: fixedPrice_,
                symbolHash: symbolHash_
        });

        if (symbols[symbolHash_] == address(0)) {
            symbols[symbolHash_] = oracle_;
        }
    }

    function setNewMUnderlying(IMToken mToken) public {
        MUnderlyingConfig storage newMUnderlyingPair = mUnderlyings[address(mToken)];
        if (momaFactory.isCodeSame(momaFactory.mErc20(), address(mToken))) {
            address targetUnderlying = mToken.underlying();
            TokenConfig memory config = tokenConfigs[targetUnderlying];
            require(config.underlyingAssetOracle != ChainlinkOracleInterface(address(0)), "Not Supported Underlying");
            newMUnderlyingPair.underlying = targetUnderlying;
            newMUnderlyingPair.isBuilt = true;
        } else if (momaFactory.isCodeSame(momaFactory.mEther(), address(mToken))) {
            newMUnderlyingPair.isBuilt = true;
            newMUnderlyingPair.isETH = true;
        } 
    }

    function setNewMUnderlyings(IMToken[] memory mTokens) public {
        for(uint i; i < mTokens.length; i++) {
            setNewMUnderlying(mTokens[i]);
        }
    }
}
