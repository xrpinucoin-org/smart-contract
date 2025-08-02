# 🧾 Presale Solidity Smart Contract

This repository contains a basic smart contract written in Solidity, designed for educational and demonstration purposes. It can be used as a boilerplate for building more complex decentralized applications (dApps).

## 📌 Features

- Written in Solidity ^0.8.x
- Simple storage contract (e.g., store and retrieve a value)
- Ready to compile, test, and deploy with Hardhat

--

## 🛠️ Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/)
- [Yarn](https://yarnpkg.com/) or npm
- [Hardhat](https://hardhat.org/)

### Install dependencies

```bash
yarn install
# or
npm install
```

### Compile contracts

```bash
npx hardhat compile
```

### Run tests
```bash
npx hardhat test
```

### Deploy contract locally
```bash
npx hardhat run scripts/deploy.js --network localhost
```

## 🚀 Deployment
You can configure networks like Sepolia or Ethereum in hardhat.config.js and deploy with:
```bash
npx hardhat run scripts/deploy.js --network sepolia
```
Make sure to:
Set up .env with your private key and RPC URLs
Fund your wallet with testnet ETH

## 📄 License
This project is licensed under the MIT License. Feel free to use and modify it.

## 🤝 Contributing
Pull requests are welcome. For major changes, please open an issue first
