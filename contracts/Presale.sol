// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// @dev Struct representing a sale stage.
/// - usdPrice is stored as an integer multiplied by 10^8 to avoid floating point errors in Solidity.
///   For example, if the USD price is $1.23, usdPrice will be stored as 123000000.
/// @param totalAmount The total number of tokens allocated for this stage.
/// @param usdPrice The price per token in USD, scaled by 10^8.
/// @param remainAmount The number of tokens remaining for sale in this stage.
struct Stage {
    uint256 totalAmount;
    uint256 usdPrice;
    uint256 remainAmount;
}

// Minimal interface for ERC20 tokens with decimals
interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

contract Presale is AccessControl, Pausable, ReentrancyGuard {
    AggregatorV3Interface internal ethPriceFeed;
    AggregatorV3Interface internal usdtPriceFeed;

    bytes32 public constant PAUSER = keccak256(abi.encodePacked(("PAUSER")));
    bytes32 public constant EMERGENCY_WITHDRAW =
        keccak256(abi.encodePacked(("EMERGENCY_WITHDRAW")));
    bytes32 public constant STAGE_REGISTER =
        keccak256(abi.encodePacked(("STAGE_REGISTER")));

    address public immutable XRPINU =
        0x7CB8b87E61fd3cc4B15F3B532AD3E36b62F7cDe3;
    address public immutable USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    uint8 public enableStage;
    bool public canClaim;

    mapping(uint8 => Stage) _stages;
    mapping(address => uint256) _claimables;

    event StageRegisted(uint8 stage, uint256 totalAmount, uint256 usdPrice);
    event StageActived(uint8 stage);
    event ClaimActived(bool canClaim);
    event Bought(
        uint8 stage,
        address buyer,
        address token,
        uint256 amount,
        int256 price,
        uint256 xrpinuAmount
    );
    event Claimed(address recipient, uint256 amount);
    event EmergencyWithdrawal(address recipient, address token, uint256 amount);

    constructor(address _owner) {
        require(_owner != address(0), "Owner cannot be zero");

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(PAUSER, _owner);
        _grantRole(EMERGENCY_WITHDRAW, _owner);
        _grantRole(STAGE_REGISTER, _owner);

        ethPriceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        usdtPriceFeed = AggregatorV3Interface(
            0x3E7d1eAB13ad0104d2750B8863b489D65364e32D
        );
    }

    function registryStage(
        uint8 stage,
        uint256 totalAmount,
        uint256 usdPrice
    ) external onlyRole(STAGE_REGISTER) {
        require(totalAmount > 0, "Total amount must be greater than 0");
        require(usdPrice > 0, "Price must be greater than zero");
        require(_stages[stage].totalAmount == 0, "Stage is already existed");

        _stages[stage] = Stage(totalAmount, usdPrice, totalAmount);
        emit StageRegisted(stage, totalAmount, usdPrice);
    }

    function activeStage(uint8 stage) external onlyRole(STAGE_REGISTER) {
        require(stage != enableStage, "Stage is already actived");
        enableStage = stage;

        emit StageActived(stage);
    }

    function toggleClaimStatus() external onlyRole(STAGE_REGISTER) {
        canClaim = !canClaim;

        emit ClaimActived(canClaim);
    }

    function buy(
        address token,
        uint256 amount
    ) external payable nonReentrant whenNotPaused {
        require(enableStage != 0, "No active stage");
        require(amount > 0, "Amount must be greater than 0");
        require(token == address(0) || token == USDT, "Unsupported token");

        Stage storage stage = _stages[enableStage];
        require(stage.remainAmount > 0, "Stage sold out");

        uint256 claimableAmount;
        int256 price;
        if (token == address(0)) {
            require(msg.value == amount, "Invalid amount");
            // ETH payment
            uint256 ethToUsd;
            (price, ethToUsd) = getEthToUsd(amount);
            claimableAmount =
                (ethToUsd * 10 ** IERC20Decimals(XRPINU).decimals()) /
                stage.usdPrice;
        } else {
            // USDT payment
            IERC20(token).transferFrom(msg.sender, address(this), amount);

            uint256 usdtToUsd;
            (price, usdtToUsd) = getUsdtToUsd(amount);
            claimableAmount =
                (usdtToUsd * 10 ** IERC20Decimals(XRPINU).decimals()) /
                stage.usdPrice;
        }
        _claimables[msg.sender] += claimableAmount;
        stage.remainAmount -= claimableAmount;
        emit Bought(
            enableStage,
            msg.sender,
            token,
            amount,
            price,
            claimableAmount
        );
    }

    function claim() external nonReentrant whenNotPaused {
        require(canClaim, "Can not claim at this time");
        require(_claimables[msg.sender] > 0, "Nothing to claim");

        uint256 claimAmount = _claimables[msg.sender];
        delete _claimables[msg.sender];

        IERC20(XRPINU).transfer(msg.sender, claimAmount);

        emit Claimed(msg.sender, claimAmount);
    }

    function pause() external onlyRole(PAUSER) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER) {
        _unpause();
    }

    function emergencyWithdraw(
        address token,
        uint256 amount
    ) external onlyRole(EMERGENCY_WITHDRAW) {
        require(amount > 0, "Zero amount");

        if (token == address(0)) {
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Withdraw failed");
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }

        emit EmergencyWithdrawal(msg.sender, token, amount);
    }

    function stageInfor(uint8 stage) external view returns (Stage memory) {
        return _stages[stage];
    }

    function claimable(address recipient) external view returns (uint256) {
        return _claimables[recipient];
    }

    function getEthToUsd(
        uint256 ethAmount
    ) public view returns (int256, uint256) {
        (, int256 price, , , ) = ethPriceFeed.latestRoundData();
        require(price > 0, "Invalid ETH price");
        return (price, (ethAmount * uint256(price)) / 1e18);
    }

    function getUsdtToUsd(
        uint256 usdtAmount
    ) public view returns (int256, uint256) {
        (, int256 price, , , ) = usdtPriceFeed.latestRoundData();
        require(price > 0, "Invalid USDT price");
        return (price, (usdtAmount * uint256(price)) / 1e6);
    }

    receive() external payable {}
}
