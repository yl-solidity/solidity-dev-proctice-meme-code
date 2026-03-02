import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ShibaInuStyleTokenModule", (m) => {

  // 部署参数
  const initName = m.getParameter("name","SIB Style Token");
  const initSymbol = m.getParameter("symbol","SIBSTYLE"); 
  const initSupply = m.getParameter("initalSupply", 1_000_000_000_000) // 1万亿
  const initWallet = m.getParameter("_marketingWallet", "0x70997970C51812dc3A010C7d01b50e0d17dc79C8")// 默认营销钱包
 
   // 部署合约
   const token = m.contract("ShibaInuStyleToken",[
    initName,
    initSymbol,
    initSupply,
    initWallet
   ])

   return { token }

});