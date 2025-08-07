const hre = require("hardhat");
const ethers = require("ethers")

const CONTRACT_NAME = "Presale"

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    const provider = hre.ethers.provider;
    console.log("Deployer address: ", deployer.address);

    console.log("Deployer balance: ", ethers.formatEther((await provider.getBalance(deployer.address)).toString()));

    // Replace with your contract name and constructor arguments if any
    const presaleArtifact = await hre.ethers.getContractFactory(CONTRACT_NAME);
    const presale = presaleArtifact.attach("0xDF24341E196698B03A731AD3377469b33Ba5d896");

    const role = "";
    const grantedAddress = ""
    const tx = await (await presale.grantRole()).wait()
    console.log(tx);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });