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
    address public marketingWallet; // 营销钱包地址
    address public lpWallet; // 用于添加流动性的钱包（可设置合约本身）


    // ----- 交易限制相关变量 ---------
    uint256 public maxTransactionAmount; // 单笔最大交易额
    uint256 public maxWalletAmount; // 单地址最大持仓量
    mapping(address=>bool) public isExcludeFromTax; // 免税地址
    mapping (address=>bool) public isExcludeFromLimit; // 免限地址
    mapping(address=>bool) public automatedMarketMakerPairs; // 免税地址

    // 事件
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address _marketingWallet
    ) ERC20(name, symbol) Ownable(msg.sender) {
        marketingWallet = _marketingWallet;

        uint256 totalSupply = initialSupply * 10 ** decimals();
        super._mint(msg.sender, totalSupply);

        // 初始化限制，最大交易额 = 总供应量的1%,最大持仓=总供应量的2%
        maxTransactionAmount = totalSupply * 1/100;
        maxWalletAmount = totalSupply * 2/100;

        // 合约部署者默认免税，限免
        isExcludeFromLimit[msg.sender] = true;
        isExcludeFromTax[msg.sender] = true;
    }

    // -----------代币税功能--重写_update函数------
    function _update(address sender, address recipient, uint256 amount) internal override {

         // 特殊处理：铸造 (sender 是零地址) 或 销毁 (recipient 是零地址)
        // 这些操作应直接通过，不应用任何税费或限制逻辑
        if (sender == address(0) || recipient == address(0)) {
            super._update(sender, recipient, amount);
            return;
        }
        require(sender != address(0), "ERC20:transfer from the zero address");
        require(recipient != address(0), "ERC20:transfer from the zero address");

        // 处理交易限制，排除白名单

        if(!isExcludeFromLimit[sender] && !isExcludeFromLimit[sender]){
            require(amount < maxTransactionAmount, "Transfer amount exceeds maxTransactionAmount");

             // 如果是买卖操作（与 AMM 池交互），检查接收方的最终持仓
            if(automatedMarketMakerPairs[recipient] || automatedMarketMakerPairs[sender]){
                // 如果是买卖操作，检查持仓限制
                require(balanceOf(recipient) + amount <= maxWalletAmount, "Recipiet exceeds max walet amount");
            }
        }

        // 计算税费，排除白名单
        uint256 taxAmount = 0;
        if(!isExcludeFromLimit[sender] && !isExcludeFromTax[recipient]){
            if(automatedMarketMakerPairs[sender]){
                // 买入，使用买入税
                taxAmount = amount * buyTax / 100;
            } else {
                // 卖出，使用卖出税
                taxAmount = amount * sellTax / 100;
            }
        }

        if(taxAmount > 0) {
            // 1. 先将税费部分转给营销钱包（通过父类的 _update 逻辑）
            super._update(sender, marketingWallet, taxAmount);
            // 2. 再转剩余部分给接收方
            super._update(sender, recipient, amount - taxAmount);
        } else {
            // 无税，正常转账
            super._update(sender, recipient, amount);
        }
    }

    // 设置税率
    function setTax(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        require(_buyTax <= 20 && _sellTax <=20, "Tax too hige");

        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    //设置AMM池地址（例如Uniswap Pair）
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        automatedMarketMakerPairs[pair] = value;
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