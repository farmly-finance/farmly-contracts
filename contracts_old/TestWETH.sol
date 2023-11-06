pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestWETH is ERC20 {
    constructor() ERC20("Ethereum WETH Test Token", "WETH") {
        _mint(msg.sender, 100000000 * 1e18);
    }
}
