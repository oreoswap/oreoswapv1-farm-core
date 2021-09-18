const OreoToken = artifacts.require("OreoToken");
const MilkBar = artifacts.require("MilkBar");
const PastryChef = artifacts.require("PastryChef");
const SousChef = artifacts.require("SousChef");

module.exports = async function(deployer) {

    const token = await deployer.deploy(OreoToken);
    await token.deployed();
    console.log("Oreotoken Address: ", token.address);

    const milk = await deployer.deploy(MilkBar, token.address);
    await milk.deployed();
    console.log("MilkBar Address: ", milk.address);

    const pastry = await deployer.deploy(PastryChef, token.address, milk.address, '0x146BB7a8F1572784610Ba8964150ac0B87a160F1', 1000, 12474143);
    await pastry.deployed();
    console.log("Pastry Address: ", pastry.address);

    const sous = await deployer.deploy(SousChef);
    await sous.deployed();
    console.log("Sousbar Address: ", sous.address);


};