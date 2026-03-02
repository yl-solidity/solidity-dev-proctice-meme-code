// SPDX-License-Identifier:MIT

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ShibaInuStyleToken
 * @dev 仿SHIB风格的Meme代币，包含交易税、流动性池集成和交易限制功能。
 */
 contract ShibaInuStyleToken is ERC20, Ownable {

    // ---代币相关变量--
    uint256 public buyTax = 5; // 买入税率5%
    uint256 public sellTax = 5; // 卖出税率5%
    uint256 public marketingWallet; // 营销钱包地址
    address public lpWallet; // 用于添加流动性的钱包（可设置合约本身）


    // ----- 交易限制相关变量 ---------
    uint256 public maxTransactionAmount; // 单笔最大交易额
    uint256 public maxWalletAmount; // 单地址最大持仓量
    mapping(address=>bool) public isExcludeFromTax; // 免税地址
    mapping (address=>bool) public isExcludeFromLimit; // 免限地址
    mapping(address=>bool) public automateMarketMarkerPairs; // 免税地址
    mapping (address=>bool) public isExcludeFromLimit; // 免限地址

    // 事件
    event SetAutomatedMarketMakerPair(address indexed pair, boll indexed value);
    event SwapAndLiquify(address tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initalSupply,
        address _marketingWallet
    ) ERC20(name, symbol) Ownable(msg.sender) {
        marketingWallet = _marketingWallet;

        uint256 totalSupply = initalSupply * 10 ** decimals();
        _mint(msg.sender, totalSupply);

        // 初始化限制，最大交易额 = 总供应量的1%,最大持仓=总供应量的2%
        maxTransactionAmount = totalSupply * 1/100;
        maxWalletAmount = totalSupply * 2/100;

        // 合约部署者默认免税，限免
        isExcludeFromLimit[msg.sender] = true;
        isExcludeFromTax[msg.sender] = true;
    }

    // -----------代币税功能--------
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20:transfer from the zero address");
        require(recipient != address(0), "ERC20:transfer from the zero address");

        // 处理交易限制，排除白名单

        if(!isExcludeFromLimit[sender] && !isExcludeFromTax[sender]){
            require(amount < maxTransactionAmount, "Transfer amount exceeds maxTransactionAmount");
            if(automateMarketMarkerPairs[recipient] || automateMarketMarkerPairs[sender]){
                // 如果是买卖操作，检查持仓限制
                require(balanceof(recipient) + amount <= maxWalletAmount, "Recipiet exceeds max walet amount");
            }
        }

        // 计算税费，排除白名单
        uint256 taxAmount = 0;
        if(!isExcludeFromLimit[sender] && !isExcludeFromTax[recipient]){
            if(automateMarketMarkerPairs[sender]){
                // 买入，使用买入税
                taxAmount = amount * buyTax / 100;
            } else {
                // 卖出，使用卖出税
                taxAmount = amount * sellTax / 100;
            }
        }

        if(taxAmount > 0) {
            // 税费转至营销钱包（简化处理，实际可拆分为LP和营销）
            super._transfer(sender, marketingWallet, taxAmount);
            amount = amount - taxAmount;
        }

        // 执行转账操作
        super._transfer(sender, recipient, amount);
    }

    // 设置税率
    function setTax(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        require(_buyTax <= 20 && _sellTax <=20, "Tax too hige");

        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    //设置AMM池地址（例如Uniswap Pair）
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        automateMarketMarkerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // 设置豁免地址
    function setExludeFromTax(address account, bool exluded) external onlyOwner{
        isExcludeFromTax[account] = exluded;
    }
        // 设置豁免地址
    function setExludeFromLimit(address account, bool exluded) external onlyOwner{
        isExcludeFromLimit[account] = exluded;
    }
        // 更新限制阈值
    function updateLimits(uint256 newMaxTx, uint256 newMaxWallet) external onlyOwner{
        maxTransactionAmount = newMaxTx;
        maxWalletAmount = newMaxWallet;
    }
 }