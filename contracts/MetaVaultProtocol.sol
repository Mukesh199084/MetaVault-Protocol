// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title MetaVault Protocol
 * @notice A decentralized vault where users deposit ERC-20 tokens to earn yield.
 * Admin can set yield rate and manage vault operations.
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MetaVaultProtocol {
    IERC20 public depositToken;
    address public owner;
    uint256 public interestRatePerSecond; // interest per second, 18 decimals

    struct UserInfo {
        uint256 deposited;
        uint256 rewardDebt;
        uint256 lastUpdated;
    }

    mapping(address => UserInfo) public users;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event InterestRateUpdated(uint256 newRate);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _depositToken, uint256 _interestRatePerSecond) {
        depositToken = IERC20(_depositToken);
        interestRatePerSecond = _interestRatePerSecond;
        owner = msg.sender;
    }

    function _pendingRewards(address user) internal view returns (uint256) {
        UserInfo memory u = users[user];
        if (u.deposited == 0) return 0;
        uint256 duration = block.timestamp - u.lastUpdated;
        return u.deposited * interestRatePerSecond * duration / 1e18;
    }

    function _updateRewards(address user) internal {
        if (users[user].deposited > 0) {
            users[user].rewardDebt += _pendingRewards(user);
        }
        users[user].lastUpdated = block.timestamp;
    }

    /** Deposit tokens to the vault */
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount > 0");
        _updateRewards(msg.sender);

        users[msg.sender].deposited += amount;
        depositToken.transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
    }

    /** Withdraw tokens and accumulated rewards */
    function withdraw(uint256 amount) external {
        require(users[msg.sender].deposited >= amount, "Insufficient balance");
        _updateRewards(msg.sender);

        uint256 totalReward = users[msg.sender].rewardDebt;
        users[msg.sender].rewardDebt = 0;
        users[msg.sender].deposited -= amount;

        depositToken.transfer(msg.sender, amount + totalReward);

        emit Withdrawn(msg.sender, amount, totalReward);
    }

    /** View pending rewards for a user */
    function pendingRewards(address user) external view returns (uint256) {
        return users[user].rewardDebt + _pendingRewards(user);
    }

    /** Admin updates interest rate */
    function setInterestRate(uint256 newRatePerSecond) external onlyOwner {
        interestRatePerSecond = newRatePerSecond;
        emit InterestRateUpdated(newRatePerSecond);
    }

    /** Emergency withdrawal of vault tokens by owner */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        depositToken.transfer(owner, amount);
    }

    /** Get user's deposited balance */
    function getDeposited(address user) external view returns (uint256) {
        return users[user].deposited;
    }
}
