pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSDC is ERC20 {
    constructor() ERC20("USDCoin USDC Test Token", "USDC") {
        _mint(msg.sender, 100000000 * 1e18);
    }
}
