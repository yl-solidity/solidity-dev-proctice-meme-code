// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/ShibaInuStyleToken.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract DeployLiquidity is Script {
    // Sepolia 测试网已部署的合约地址
    address constant UNISWAP_V2_FACTORY = 0x7E0987E5b3a30e3f2828572Bb659A548460a3003;
    address constant UNISWAP_V2_ROUTER = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;
    address constant WETH = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    
    // 你的代币地址（Sepolia）
    address constant YOUR_TOKEN = 0x1040692AB23Df0C876209fBe02f501365C75a339;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. 获取代币合约实例
        ShibaInuStyleToken token = ShibaInuStyleToken(YOUR_TOKEN);
        
        // 2. 将 Router 和 Factory 加入豁免名单
        console.log("Adding Router and Factory to exemption lists...");
        token.setExludeFromLimit(UNISWAP_V2_ROUTER, true);
        token.setExludeFromTax(UNISWAP_V2_ROUTER, true);
        token.setExludeFromLimit(UNISWAP_V2_FACTORY, true);
        token.setExludeFromTax(UNISWAP_V2_FACTORY, true);
        
        // 3. 检查或创建交易对
        IUniswapV2Factory factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
        address pair = factory.getPair(YOUR_TOKEN, WETH);
        
        if (pair == address(0)) {
            console.log("Creating new pair...");
            pair = factory.createPair(YOUR_TOKEN, WETH);
            console.log("Pair created at:", pair);
        } else {
            console.log("Pair already exists at:", pair);
        }
        
        // 4. 将 Pair 标记为 AMM 池
        token.setAutomatedMarketMakerPair(pair, true);
        
        // 5. 添加初始流动性
        IUniswapV2Router02 router = IUniswapV2Router02(UNISWAP_V2_ROUTER);
        
        // 设置流动性数量
        uint256 tokenAmount = 1_000_000 * 10**18; // 100万代币
        uint256 ethAmount = 0.1 ether; // 0.1 ETH
        
        // 授权路由器使用代币
        console.log("Approving tokens...");
        token.approve(UNISWAP_V2_ROUTER, tokenAmount);
        
        // 添加流动性
        console.log("Adding liquidity...");
        router.addLiquidityETH{value: ethAmount}(
            YOUR_TOKEN,
            tokenAmount,
            0, // 最小代币数量（测试网可设为0）
            0, // 最小ETH数量（测试网可设为0）
            deployer,
            block.timestamp + 15 minutes
        );
        
        console.log("Liquidity added successfully");
        console.log("Pair address:", pair);
        
        vm.stopBroadcast();
    }
}