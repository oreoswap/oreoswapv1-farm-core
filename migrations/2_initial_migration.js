const Web3 = require("web3");
const OreoToken = artifacts.require("OreoToken");
const MilkBar = artifacts.require("MilkBar");
const PastryChef = artifacts.require("PastryChef");
const SousChef = artifacts.require("SousChef");

module.exports = async function(deployer) {

    await deployer.deploy(OreoToken);
    const token = await OreoToken.deployed();
    // const token = await OreoToken.new();
    console.log("Oreotoken Address: ", token.address);

    await deployer.deploy(MilkBar, token.address);
    const milk = await MilkBar.deployed
    // const milk = await MilkBar.new(token.address);
    console.log("MilkBar Address: ", milk.address);

    await deployer.deploy(PastryChef, token.address, milk.address, '0x146BB7a8F1572784610Ba8964150ac0B87a160F1', 1000, 12474143);
    const pastry = await PastryChef.deployed();
    // const pastry = await PastryChef.new(token.address, milk.address, '0x146BB7a8F1572784610Ba8964150ac0B87a160F1', 1000, 12474143);
    console.log("Pastry Address: ", pastry.address);

    await deployer.deploy(SousChef, milk.address, 1000, 12474143, 12475143);
    await SousChef.deployed();
    // const sous = await SousChef.new(milk.address, 1000, 12474143, 12475143);
    // contract("SOUCHEF", accounts => {
    //     let sou
    //     Before( async () => {
    //         sou = await SousChef.new(milk.address, 1000, 12474143, 12475143);
    //     });

        

    //     it(

    //     );
    // }

    // );
    // console.log("Sousbar Address: ", sous.address); 
    // console.log("Others: ", Web3.utils.BN(await sous._now.call()).toNumber()); 
    // console.log("Starttime: ", Web3.utils.BN(await sous.starttime.call()).toNumber()); 
    // console.log("Sousbar Address: ", sous.address); 


};