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
    const presale = presaleArtifact.attach("0x2Cac392BAb532a2E290E1c4972e0e8A89CB1adc0");

    const role = "";
    const grantedAddress = ""
    const tx = await (await presale.grantRole()).wait()
    console.log(tx);
    
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