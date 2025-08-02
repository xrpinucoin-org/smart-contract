const hre = require("hardhat");
const ethers = require("ethers");
const { default: Decimal } = require("decimal.js");

const CONTRACT_NAME = "Presale"

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    const provider = hre.ethers.provider;
    console.log("Deployer address: ", deployer.address);
    console.log("Deployer balance: ", ethers.formatEther((await provider.getBalance(deployer.address)).toString()));

    const presaleArtifact = await hre.ethers.getContractFactory(CONTRACT_NAME);
    const presale = presaleArtifact.attach("0x2Cac392BAb532a2E290E1c4972e0e8A89CB1adc0");

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