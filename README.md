# Open-Oracle接口文档
## PriceOracleProxy
* 功能描述：
  + 供mToken、mETH合约获取去精度价格；

* Contract Address:
  + Rinkeby: 0xdeC3767A8642eA44482b606d51843fa2Bb0Bac44

### View Func：
#### 1. getUnderlyingPrice:
* 功能描述：供mToken合约获取原生资产的去精度因素价格，mul(1e28, priceInternal(tokenConfig)) / tokenConfig.baseUnit；
* 入参：
  
|参数名称|参数类型|说明|
|---|---|---|
|mToken|address|待查询mToken地址|

* 返回值

|参数名称|参数类型|说明|
|---|---|---|
|underlyingPrice|uint|去精度因素价格|

## SimpleMomaProiceOracleV1
* 功能描述：
  + 维护mToken对chainlink的对应关系，并集合chainlink多交易对报价；

* Contract Address:
  + Rinkeby: 0x7BE5d3f7A52a4470871B19F3c0dae2FD59f8c19A

### View Func：
#### 1. assetPrices:
* 功能描述：供mToken合约获取原生资产的去精度因素价格，mul(1e28, priceInternal(tokenConfig)) / tokenConfig.baseUnit；
* 入参：
  
|参数名称|参数类型|说明|
|---|---|---|
|mToken|address|待查询mToken地址|

* 返回值：

|参数名称|参数类型|说明|
|---|---|---|
|underlyingPrice|uint|去精度因素价格|

#### 2. getPrice:
* 功能描述：获取指定原生资产价格（8位精度）；
* 入参：
  
|参数名称|参数类型|说明|
|---|---|---|
|underlyingAsset|address|待查询原生资产合约地址|

* 返回值：

|参数名称|参数类型|说明|
|---|---|---|
|price|uint|去精度因素价格|

### Change State Func：
#### 1. setNewOracle:
* 功能描述：管理员添加新的chainlink oracle；
* 入参：

|参数名称|参数类型|说明|
|---|---|---|
|oracle_|address|新增oracle合约地址|
|underlying_|address|新增oracle原生资产合约地址|
|baseUnit_|uint256|原生资产基础精度|
|priceSource_|uint256|价格源标记（0：FIXED_ETH、1：FIXED_USD、2、REPORTER）|
|fixedPrice_|uint256|固定价格，当原生资产为非固定价格时置空|

#### 2. setNewOracle:
* 功能描述：绑定mToken至已有原生资产oracle；
* 入参：

|参数名称|参数类型|说明|
|---|---|---|
|mToken|address|新增mToken合约地址|
|isETH_|bool|新增mToken的原生资产是否为ETH|
