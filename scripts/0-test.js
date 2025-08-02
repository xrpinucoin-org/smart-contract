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
    const presale = presaleArtifact.attach("0x6F84DFE78bC3c379e5D75f0a24EaA7B81247E2d1");

    console.log("Presale rate:", await presale.getLatestPrice());
}
// else {
//     // USDT payment
//     claimable =
//         (amount * 10 ** IERC20Decimals(XRPINU).decimals()) /
//         stage.usdPrice;
// }
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });