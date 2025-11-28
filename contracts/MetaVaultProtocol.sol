------------------------------------------------------
    ------------------------------------------------------
    event Deposit(address indexed user, uint256 amount, uint256 sharesMinted);
    event Withdraw(address indexed user, uint256 amount, uint256 sharesBurned);
    event StrategyUpdated(address indexed newStrategy);
    event Paused(address indexed by);
    event Unpaused(address indexed by);

    STORAGE
    e.g., USDC, DAI
    IStrategy public strategy;              ------------------------------------------------------
    ------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    CONSTRUCTOR
    ------------------------------------------------------
    ------------------------------------------------------
    function totalAssets() public view returns (uint256) {
        uint256 vaultBalance = asset.balanceOf(address(this));
        uint256 strategyBalance = strategy.totalAssets();
        return vaultBalance + strategyBalance;
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        return (totalShares == 0) ? assets : (assets * totalShares / totalAssets());
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        return (totalShares == 0) ? shares : (shares * totalAssets() / totalShares);
    }

    CORE VAULT LOGIC
    Pull tokens
        asset.transferFrom(msg.sender, address(this), amount);

        Optionally auto-deposit into strategy
        if (address(strategy) != address(0)) {
            asset.approve(address(strategy), amount);
            strategy.deposit(amount);
        }
    }

    function withdraw(uint256 shares) external notPaused returns (uint256 assetsOut) {
        require(shares > 0, "Shares = 0");
        require(shareBalance[msg.sender] >= shares, "Not enough shares");

        assetsOut = convertToAssets(shares);

        If assets are in strategy, withdraw them
        uint256 vaultBalance = asset.balanceOf(address(this));
        if (vaultBalance < assetsOut) {
            uint256 needed = assetsOut - vaultBalance;
            strategy.withdraw(needed);
        }

        asset.transfer(msg.sender, assetsOut);
    }

    OWNER FUNCTIONS
    // ------------------------------------------------------
    function setStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), "Invalid strategy");
        strategy = IStrategy(_strategy);
        emit StrategyUpdated(_strategy);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        if (_paused) emit Paused(msg.sender);
        else emit Unpaused(msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero addr");
        owner = newOwner;
    }
}
// 
Contract End
// 
