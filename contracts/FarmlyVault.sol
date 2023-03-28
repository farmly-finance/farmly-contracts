pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./FarmlyConfig.sol";

contract FarmlyVault is ERC20, FarmlyConfig {
    using Math for uint;

    IERC20 public token;
    uint public totalBorrowed;
    uint public lastAction;

    constructor(IERC20 _token) ERC20("Farmly ETH Interest Bearing", "flyETH") {
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
            totalBorrowed += interest;
            lastAction = block.timestamp;
        }
        _;
    }

    function deposit(
        uint256 amount
    ) public transferToken(amount) update(amount) {
        _mint(
            msg.sender,
            (totalToken() - amount) == 0
                ? amount
                : (amount * totalSupply()) / (totalToken() - amount)
        );
    }

    // totalSupply = ibETH
    // totalToken = deposited ETH

    function withdraw(uint256 amount) public update(0) {
        uint256 tokenAmount = (amount * totalToken()) / totalSupply();
        _burn(msg.sender, amount);
        token.transfer(msg.sender, tokenAmount);
    }

    function totalToken() public view returns (uint256) {
        return token.balanceOf(address(this)) + totalBorrowed;
    }

    function pendingInterest(uint256 value) public view returns (uint256) {
        if (block.timestamp > lastAction) {
            uint256 timePast = block.timestamp - lastAction;
            uint256 balance = token.balanceOf(address(this)) +
                totalBorrowed -
                value;
            return
                (getBorrowAPR(totalBorrowed, balance) *
                    timePast *
                    totalBorrowed) / 100e18;
        } else {
            return 0;
        }
    }

    function borrow(uint256 amount) public update(amount) {
        token.transfer(msg.sender, amount);
        totalBorrowed += amount;
    }

    function close()
        public
        transferToken(totalBorrowed + pendingInterest(0))
        update(totalBorrowed + pendingInterest(0))
        returns (uint256)
    {
        totalBorrowed -= totalBorrowed;
        return totalBorrowed;
    }

    function addBorrower() public {}

    function removeBorrower() public {}
}
