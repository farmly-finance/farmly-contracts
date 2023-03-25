pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("Ethereum Test Token", "tETH") {
        _mint(msg.sender, 100000000 * 1e18);
    }
}
