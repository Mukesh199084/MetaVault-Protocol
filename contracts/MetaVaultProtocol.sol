State variables
    address public owner;
    uint256 public totalDeposits;
    uint256 public vaultCount;
    
    Mappings
    mapping(address => Vault[]) public userVaults;
    mapping(uint256 => Vault) public vaults;
    mapping(address => uint256) public userTotalBalance;
    
    Modifiers
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
        
        Update in user's vault array
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
        
        Fallback function to receive Ether
    receive() external payable {
        totalDeposits += msg.value;
    }
}
// 
End
// 
