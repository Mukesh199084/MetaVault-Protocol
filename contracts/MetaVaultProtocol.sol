// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MetaVault Protocol
 * @dev A decentralized vault system for secure asset storage and management
 * @notice This contract allows users to deposit, withdraw, and manage their crypto assets
 */
contract MetaVaultProtocol {
    
    // State variables
    address public owner;
    uint256 public totalDeposits;
    uint256 public vaultCount;
    
    // Struct to represent a vault
    struct Vault {
        uint256 id;
        address owner;
        uint256 balance;
        uint256 depositTime;
        bool isActive;
    }
    
    // Mappings
    mapping(address => Vault[]) public userVaults;
    mapping(uint256 => Vault) public vaults;
    mapping(address => uint256) public userTotalBalance;
    
    // Events
    event VaultCreated(uint256 indexed vaultId, address indexed owner, uint256 timestamp);
    event DepositMade(uint256 indexed vaultId, address indexed owner, uint256 amount);
    event WithdrawalMade(uint256 indexed vaultId, address indexed owner, uint256 amount);
    event VaultClosed(uint256 indexed vaultId, address indexed owner);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this");
        _;
    }
    
    modifier vaultExists(uint256 _vaultId) {
        require(vaults[_vaultId].isActive, "Vault does not exist or is inactive");
        _;
    }
    
    modifier onlyVaultOwner(uint256 _vaultId) {
        require(vaults[_vaultId].owner == msg.sender, "You are not the vault owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        vaultCount = 0;
        totalDeposits = 0;
    }
    
    /**
     * @dev Core Function 1: Create a new vault
     * @notice Creates a new vault for the user with an initial deposit
     * @return vaultId The ID of the newly created vault
     */
    function createVault() external payable returns (uint256) {
        require(msg.value > 0, "Initial deposit must be greater than 0");
        
        vaultCount++;
        uint256 newVaultId = vaultCount;
        
        Vault memory newVault = Vault({
            id: newVaultId,
            owner: msg.sender,
            balance: msg.value,
            depositTime: block.timestamp,
            isActive: true
        });
        
        vaults[newVaultId] = newVault;
        userVaults[msg.sender].push(newVault);
        userTotalBalance[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit VaultCreated(newVaultId, msg.sender, block.timestamp);
        emit DepositMade(newVaultId, msg.sender, msg.value);
        
        return newVaultId;
    }
    
    /**
     * @dev Core Function 2: Deposit funds into an existing vault
     * @param _vaultId The ID of the vault to deposit into
     */
    function deposit(uint256 _vaultId) external payable vaultExists(_vaultId) onlyVaultOwner(_vaultId) {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        vaults[_vaultId].balance += msg.value;
        userTotalBalance[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        // Update in user's vault array
        Vault[] storage userVaultList = userVaults[msg.sender];
        for (uint256 i = 0; i < userVaultList.length; i++) {
            if (userVaultList[i].id == _vaultId) {
                userVaultList[i].balance += msg.value;
                break;
            }
        }
        
        emit DepositMade(_vaultId, msg.sender, msg.value);
    }
    
    /**
     * @dev Core Function 3: Withdraw funds from a vault
     * @param _vaultId The ID of the vault to withdraw from
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _vaultId, uint256 _amount) external vaultExists(_vaultId) onlyVaultOwner(_vaultId) {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(vaults[_vaultId].balance >= _amount, "Insufficient vault balance");
        
        vaults[_vaultId].balance -= _amount;
        userTotalBalance[msg.sender] -= _amount;
        totalDeposits -= _amount;
        
        // Update in user's vault array
        Vault[] storage userVaultList = userVaults[msg.sender];
        for (uint256 i = 0; i < userVaultList.length; i++) {
            if (userVaultList[i].id == _vaultId) {
                userVaultList[i].balance -= _amount;
                break;
            }
        }
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit WithdrawalMade(_vaultId, msg.sender, _amount);
    }
    
    /**
     * @dev Core Function 4: Get vault details
     * @param _vaultId The ID of the vault to query
     * @return id The unique identifier of the vault
     * @return vaultOwner The address of the vault owner
     * @return balance The current balance in the vault
     * @return depositTime The timestamp when the vault was created
     * @return isActive The status of the vault (true if active, false if closed)
     */
    function getVaultDetails(uint256 _vaultId) external view vaultExists(_vaultId) returns (
        uint256 id,
        address vaultOwner,
        uint256 balance,
        uint256 depositTime,
        bool isActive
    ) {
        Vault memory vault = vaults[_vaultId];
        return (
            vault.id,
            vault.owner,
            vault.balance,
            vault.depositTime,
            vault.isActive
        );
    }
    
    /**
     * @dev Core Function 5: Close vault and withdraw all funds
     * @param _vaultId The ID of the vault to close
     */
    function closeVault(uint256 _vaultId) external vaultExists(_vaultId) onlyVaultOwner(_vaultId) {
        uint256 balance = vaults[_vaultId].balance;
        
        vaults[_vaultId].balance = 0;
        vaults[_vaultId].isActive = false;
        userTotalBalance[msg.sender] -= balance;
        totalDeposits -= balance;
        
        // Update in user's vault array
        Vault[] storage userVaultList = userVaults[msg.sender];
        for (uint256 i = 0; i < userVaultList.length; i++) {
            if (userVaultList[i].id == _vaultId) {
                userVaultList[i].balance = 0;
                userVaultList[i].isActive = false;
                break;
            }
        }
        
        if (balance > 0) {
            (bool success, ) = payable(msg.sender).call{value: balance}("");
            require(success, "Transfer failed");
        }
        
        emit VaultClosed(_vaultId, msg.sender);
        emit WithdrawalMade(_vaultId, msg.sender, balance);
    }
    
    /**
     * @dev Get all vaults for a specific user
     * @param _user The address of the user
     * @return Array of user's vaults
     */
    function getUserVaults(address _user) external view returns (Vault[] memory) {
        return userVaults[_user];
    }
    
    /**
     * @dev Get total balance for a user across all vaults
     * @param _user The address of the user
     * @return Total balance
     */
    function getUserTotalBalance(address _user) external view returns (uint256) {
        return userTotalBalance[_user];
    }
    
    /**
     * @dev Get contract statistics
     * @return Total number of vaults and total deposits
     */
    function getContractStats() external view returns (uint256, uint256) {
        return (vaultCount, totalDeposits);
    }
    
    /**
     * @dev Emergency withdrawal function (only contract owner)
     * @notice Allows contract owner to withdraw funds in case of emergency
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Emergency withdrawal failed");
        
        emit EmergencyWithdrawal(owner, balance);
    }
    
    // Fallback function to receive Ether
    receive() external payable {
        totalDeposits += msg.value;
    }
}