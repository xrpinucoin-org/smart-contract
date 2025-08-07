const hre = require("hardhat");
const ethers = require("ethers");

const CONTRACT_NAME = "Presale"

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    const provider = hre.ethers.provider;
    console.log("Deployer address: ", deployer.address);
    console.log("Deployer balance: ", ethers.formatEther((await provider.getBalance(deployer.address)).toString()));

    const presaleArtifact = await hre.ethers.getContractFactory(CONTRACT_NAME);
    const presale = presaleArtifact.attach("0xDF24341E196698B03A731AD3377469b33Ba5d896");

    const tx = await (await presale.toggleClaimStatus()).wait()
    console.log(tx);

    console.log("Get claim status: ", await presale.canClaim());

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });