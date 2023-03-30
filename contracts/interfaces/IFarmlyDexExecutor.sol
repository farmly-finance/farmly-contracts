pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFarmlyDexExecutor {
    function execute(
        IERC20 token0,
        IERC20 token1,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256, address);
}
