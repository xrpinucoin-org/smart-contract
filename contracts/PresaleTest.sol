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
    uint8 stageId;
    uint256 totalAmount;
    uint256 usdPrice;
    uint256 remainAmount;
}

// Minimal interface for ERC20 tokens with decimals
interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

contract PresaleTestSepolia is AccessControl, Pausable, ReentrancyGuard {
    AggregatorV3Interface internal ethPriceFeed;

    bytes32 public constant PAUSER = keccak256(abi.encodePacked(("PAUSER")));
    bytes32 public constant EMERGENCY_WITHDRAW =
        keccak256(abi.encodePacked(("EMERGENCY_WITHDRAW")));
    bytes32 public constant STAGE_REGISTER =
        keccak256(abi.encodePacked(("STAGE_REGISTER")));

    address public immutable XRPINU =
        0x69857EcE64cB4306028bE6f047077B33bE40b8a6;
    address public immutable USDT = 0xBfc2ADDEa1D83bB286C57E960720fa420e4273B8;

    address public immutable fundsReceiver;
    uint8 public enableStage;
    bool public canClaim;
    uint256 public totalSold;
    uint256 public totalRaisedInUsd; // in decimal 18

    mapping(uint8 => Stage) _stages;
    mapping(address => uint256) _claimables;

    event StageRegistered(Stage[] stages);
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

    constructor(address _owner, address _fundsReceiver) {
        require(_owner != address(0), "Owner cannot be zero");
        require(_fundsReceiver != address(0), "Funds receiver cannot be zero");

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(PAUSER, _owner);
        _grantRole(EMERGENCY_WITHDRAW, _owner);
        _grantRole(STAGE_REGISTER, _owner);

        ethPriceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );

        fundsReceiver = _fundsReceiver;
    }

    function registerStages(
        Stage[] memory stages
    ) external onlyRole(STAGE_REGISTER) {
        for (uint8 i = 0; i < stages.length; i++) {
            registerStage(stages[i]);
        }
        emit StageRegistered(stages);
    }

    function registerStage(Stage memory stage) internal {
        require(stage.totalAmount > 0, "Total amount must be greater than 0");
        require(stage.usdPrice > 0, "Price must be greater than zero");
        require(
            _stages[stage.stageId].totalAmount == 0,
            "Stage already exists"
        );

        _stages[stage.stageId] = Stage(
            stage.stageId,
            stage.totalAmount,
            stage.usdPrice,
            stage.totalAmount
        );
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
            (bool success, ) = fundsReceiver.call{value: amount}("");
            require(success, "Buy failed");

            // ETH payment
            uint256 ethToUsd;
            (price, ethToUsd) = getEthToUsd(amount);
            claimableAmount =
                (ethToUsd * 10 ** IERC20Decimals(XRPINU).decimals()) /
                stage.usdPrice;
        } else {
            // USDT payment
            IERC20(token).transferFrom(msg.sender, fundsReceiver, amount);

            uint256 usdtToUsd;
            (price, usdtToUsd) = getUsdtToUsd(amount);
            claimableAmount =
                (usdtToUsd * 10 ** IERC20Decimals(XRPINU).decimals()) /
                stage.usdPrice;
        }
        require(
            claimableAmount <= stage.remainAmount,
            "Claimable amount exceeds remain amount"
        );

        _claimables[msg.sender] += claimableAmount;
        stage.remainAmount -= claimableAmount;
        totalSold += claimableAmount;
        totalRaisedInUsd += (claimableAmount * stage.usdPrice) / 10 ** 8;

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
            (bool success, ) = fundsReceiver.call{value: amount}("");
            require(success, "Withdraw failed");
        } else {
            IERC20(token).transfer(fundsReceiver, amount);
        }

        emit EmergencyWithdrawal(fundsReceiver, token, amount);
    }

    function stageInfo(uint8 stage) external view returns (Stage memory) {
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
    ) public pure returns (int256, uint256) {
        int256 price = 100000000; // USDT is pegged to USD, so 1 USDT = 1 USD
        return (price, (usdtAmount * uint256(price)) / 1e6);
    }

    receive() external payable {}
}
