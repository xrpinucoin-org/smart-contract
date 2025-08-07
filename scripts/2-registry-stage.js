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
    const presale = presaleArtifact.attach("0xDF24341E196698B03A731AD3377469b33Ba5d896");

    const stages = [
        {
            stageId: 1,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.00001, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 2,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.000015, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 3,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.00002, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 4,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.000025, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 5,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.00003, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 6,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.000035, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 7,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.00004, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 8,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.000045, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 9,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.00005, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 10,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.000055, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 11,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.00006, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 12,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.000065, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 13,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.00007, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 14,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.000075, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
        {
            stageId: 15,
            totalAmount: ethers.parseEther("5000000000"),
            usdPrice: Decimal.mul(0.00008, Math.pow(10, 8)).toFixed(),
            remainAmount: ethers.parseEther("5000000000"),
        },
    ]

    console.log("Register stages: ", stages);

    const tx = await (await presale.registerStages(
        stages
    )).wait()
    console.log(tx);

    for (let i = 0; i < stages.length; i++) {
        console.log("Get stage information: ", await presale.stageInfo(stages[i].stageId));
    }


}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });