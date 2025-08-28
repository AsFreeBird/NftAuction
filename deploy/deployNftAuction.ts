
import {upgrades,ethers} from 'hardhat';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import path from 'path';

module.exports= async(hre:HardhatRuntimeEnvironment)=>{
    const {getNamedAccounts,deployments} = hre;
    const {save} = deployments;
    const {deployer}= await getNamedAccounts();
    console.log("部署用户地址",deployer);

    const NftAuction = await ethers.getContractFactory("NftAuction");
    //通过代理合约部署
    const  nftAuctionProxy= await upgrades.deployProxy(NftAuction,[],{initializer:'initialize'});
    await nftAuctionProxy.waitForDeployment();
    console.log("nftAuctionProxy address:",nftAuctionProxy.target);
    
};