pragma solidity >=0.5.0;

import "./interfaces/IFarmlyVault.sol";
import "./interfaces/IFarmlyConfig.sol";

import "./libraries/FarmlyFullMath.sol";
import "./libraries/FarmlyTransferHelper.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FarmlyVault is IFarmlyVault, ERC20, Ownable {
    /// @inheritdoc IFarmlyVaultImmutables
    address public immutable override token;
    /// @inheritdoc IFarmlyVaultImmutables
    IFarmlyConfig public immutable override farmlyConfig;

    /// @inheritdoc IFarmlyVaultState
    uint256 public override totalDebt;
    /// @inheritdoc IFarmlyVaultState
    uint256 public override totalDebtShare;
    /// @inheritdoc IFarmlyVaultState
    uint256 public override lastAction;
    /// @inheritdoc IFarmlyVaultState
    mapping(address => bool) public override borrower;

    modifier transferToken(uint256 amount) {
        if (amount > 0)
            FarmlyTransferHelper.safeTransferFrom(
                token,
                msg.sender,
                address(this),
                amount
            );
        _;
    }

    modifier update(uint256 amount) {
        if (block.timestamp > lastAction) {
            uint256 interest = pendingInterest(amount);
            totalDebt += interest;
            lastAction = block.timestamp;
        }
        _;
    }

    modifier onlyBorrower() {
        require(borrower[msg.sender], "NOT BORROWER");
        _;
    }

    constructor(
        IFarmlyConfig _farmlyConfig,
        address _token,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        token = _token;
        farmlyConfig = _farmlyConfig;
        lastAction = block.timestamp;
    }

    /// @inheritdoc IFarmlyVaultDerivedState
    function totalToken() public view override returns (uint256) {
        return IERC20(token).balanceOf(address(this)) + totalDebt;
    }

    /// @inheritdoc IFarmlyVaultDerivedState
    function pendingInterest(
        uint256 value
    ) public view override returns (uint256) {
        if (block.timestamp > lastAction) {
            uint256 timePast = block.timestamp - lastAction;
            uint256 balance = IERC20(token).balanceOf(address(this)) +
                totalDebt -
                value;
            IFarmlyInterestModel interestModel = farmlyConfig
                .getVaultInterestModel(address(this));

            return
                (interestModel.getBorrowAPR(totalDebt, balance) *
                    timePast *
                    totalDebt) / 100e18;
        } else {
            return 0;
        }
    }

    /// @inheritdoc IFarmlyVaultDerivedState
    function debtShareToDebt(
        uint256 debtShare
    ) public view override returns (uint256) {
        if (totalDebtShare == 0) return debtShare;
        uint256 interest = pendingInterest(0);

        return
            FarmlyFullMath.mulDiv(
                debtShare,
                totalDebt + interest,
                totalDebtShare
            );
    }

    /// @inheritdoc IFarmlyVaultDerivedState
    function debtToDebtShare(
        uint256 debt
    ) public view override returns (uint256) {
        if (totalDebtShare == 0) return debt;
        uint256 interest = pendingInterest(0);

        return
            FarmlyFullMath.mulDiv(debt, totalDebtShare, totalDebt + interest);
    }

    /// @inheritdoc IFarmlyVaultActions
    function deposit(
        uint256 amount
    ) public override transferToken(amount) update(amount) {
        require(amount > 0);
        // Mint up to the amount for the first deposit
        uint256 mintAmount = (totalToken() - amount) == 0
            ? amount
            : FarmlyFullMath.mulDiv(
                amount,
                totalSupply(),
                totalToken() - amount
            );

        _mint(msg.sender, mintAmount);

        emit Deposit(amount, mintAmount);
    }

    /// @inheritdoc IFarmlyVaultActions
    function withdraw(uint256 amount) public override update(0) {
        require(amount > 0);

        uint256 tokenAmount = FarmlyFullMath.mulDiv(
            amount,
            totalToken(),
            totalSupply()
        );

        _burn(msg.sender, amount);
        FarmlyTransferHelper.safeTransfer(token, msg.sender, tokenAmount);

        emit Withdraw(amount, tokenAmount);
    }

    /// @inheritdoc IFarmlyVaultActions
    function borrow(
        uint256 amount
    ) public override onlyBorrower update(amount) returns (uint256) {
        require(IERC20(token).balanceOf(address(this)) > amount);

        if (amount > 0)
            FarmlyTransferHelper.safeTransfer(token, msg.sender, amount);

        uint256 debtShare = _addDebt(amount);
        emit Borrow(msg.sender, amount, debtShare);
        return debtShare;
    }

    /// @inheritdoc IFarmlyVaultActions
    function close(
        uint256 amount
    )
        public
        override
        onlyBorrower
        update(0)
        transferToken(debtShareToDebt(amount))
        returns (uint256)
    {
        uint256 paidAmount = _removeDebt(amount);
        emit Close(amount, paidAmount);
        return paidAmount;
    }

    /// @inheritdoc IFarmlyVaultOwnerActions
    function addBorrower(address _borrower) public override onlyOwner {
        borrower[_borrower] = true;
        emit Borrower(_borrower, true);
    }

    /// @inheritdoc IFarmlyVaultOwnerActions
    function removeBorrower(address _borrower) public override onlyOwner {
        borrower[_borrower] = false;
        emit Borrower(_borrower, false);
    }

    // Update state variables
    function _addDebt(uint256 debtAmount) internal returns (uint256) {
        uint256 debtShare = debtToDebtShare(debtAmount);
        totalDebt += debtAmount;
        totalDebtShare += debtShare;
        return debtShare;
    }

    // Update state variables
    function _removeDebt(uint256 debtShare) internal returns (uint256) {
        uint256 debt = debtShareToDebt(debtShare);
        totalDebtShare -= debtShare;
        totalDebt -= debt;
        return debt;
    }
}
