const hre = require("hardhat");
const ethers = require("ethers")

const CONTRACT_NAME = "PresaleTestSepolia"

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    const provider = hre.ethers.provider;
    console.log("Deployer address: ", deployer.address);

    console.log("Deployer balance: ", ethers.formatEther((await provider.getBalance(deployer.address)).toString()));

    // Replace with your contract name and constructor arguments if any
    const presaleArtifact = await hre.ethers.getContractFactory(CONTRACT_NAME);
    const presale = await presaleArtifact.deploy(deployer.address);

    await presale.waitForDeployment();

    console.log("Presale contract deployed to:", presale.target);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });