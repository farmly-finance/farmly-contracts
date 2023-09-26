pragma solidity >=0.5.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./library/FarmlyFullMath.sol";
import "./FarmlyInterestModel.sol";

contract FarmlyVault is ERC20, FarmlyInterestModel, Ownable {
    using Math for uint;

    IERC20 public token;
    uint256 public totalDebt;
    uint256 public totalDebtShare;
    uint256 public lastAction;
    mapping(address => bool) public borrower;

    constructor(
        IERC20 _token,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        token = _token;
        lastAction = block.timestamp;
    }

    modifier transferToken(uint256 amount) {
        token.transferFrom(msg.sender, address(this), amount);
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

    function deposit(
        uint256 amount
    ) public transferToken(amount) update(amount) {
        _mint(
            msg.sender,
            (totalToken() - amount) == 0
                ? amount
                : FarmlyFullMath.mulDiv(
                    amount,
                    totalSupply(),
                    totalToken() - amount
                )
        );
    }

    // totalSupply = flyETH
    // totalToken = deposited ETH

    function withdraw(uint256 amount) public update(0) {
        uint256 tokenAmount = FarmlyFullMath.mulDiv(
            amount,
            totalToken(),
            totalSupply()
        );
        _burn(msg.sender, amount);
        token.transfer(msg.sender, tokenAmount);
    }

    function totalToken() public view returns (uint256) {
        return token.balanceOf(address(this)) + totalDebt;
    }

    function pendingInterest(uint256 value) public view returns (uint256) {
        if (block.timestamp > lastAction) {
            uint256 timePast = block.timestamp - lastAction;
            uint256 balance = token.balanceOf(address(this)) +
                totalDebt -
                value;
            return
                (getBorrowAPR(totalDebt, balance) * timePast * totalDebt) /
                100e18;
        } else {
            return 0;
        }
    }

    function borrow(
        uint256 amount
    ) public onlyBorrower update(amount) returns (uint) {
        token.transfer(msg.sender, amount);
        return _addDebt(amount);
    }

    function close(
        uint256 debtShare
    )
        public
        onlyBorrower
        update(0)
        transferToken(debtShareToDebt(debtShare))
        returns (uint256)
    {
        return _removeDebt(debtShare);
    }

    function _addDebt(uint256 debtAmount) internal returns (uint256) {
        uint256 debtShare = debtToDebtShare(debtAmount);
        totalDebt += debtAmount;
        totalDebtShare += debtShare;
        return debtShare;
    }

    function _removeDebt(uint256 debtShare) internal returns (uint256) {
        uint256 debt = debtShareToDebt(debtShare);
        totalDebtShare -= debtShare;
        totalDebt -= debt;
        return debt;
    }

    function debtShareToDebt(uint256 debtShare) public view returns (uint256) {
        if (totalDebtShare == 0) return debtShare;
        uint256 interest = pendingInterest(0);
        return
            FarmlyFullMath.mulDiv(
                debtShare,
                totalDebt + interest,
                totalDebtShare
            );
    }

    function debtToDebtShare(uint256 debt) public view returns (uint256) {
        if (totalDebtShare == 0) return debt;
        uint256 interest = pendingInterest(0);
        return
            FarmlyFullMath.mulDiv(debt, totalDebtShare, totalDebt + interest);
    }

    function addBorrower(address _borrower) public onlyOwner {
        borrower[_borrower] = true;
    }

    function removeBorrower(address _borrower) public onlyOwner {
        borrower[_borrower] = false;
    }
}
