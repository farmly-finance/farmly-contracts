pragma solidity >=0.5.0;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./uniV2ForksInterfaces/IUniswapV2Router01.sol";
import "./uniV2ForksInterfaces/IUniswapV2Factory.sol";
import "./uniV2ForksInterfaces/IUniswapV2Pair.sol";

contract FarmlyDexExecutor {
    using Math for uint;
    IUniswapV2Router01 public router;
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    constructor(address _router) {
        router = IUniswapV2Router01(_router);
    }

    function getOptimalSwapAmount(
        uint256 aA,
        uint256 aB,
        uint256 rA,
        uint256 rB,
        uint256 pF // 25
    ) internal pure returns (uint256 swapAmount, bool isAB) {
        if (aA * rB >= aB * rA) {
            swapAmount = _getOptimalSwapAmount(aA, aB, rA, rB, pF);
            isAB = false;
        } else {
            swapAmount = _getOptimalSwapAmount(aB, aA, rB, rA, pF);
            isAB = true;
        }
    }

    function _getOptimalSwapAmount(
        uint256 aA,
        uint256 aB,
        uint256 rA,
        uint256 rB,
        uint256 pF
    ) internal pure returns (uint256 swapAmount) {
        require(aA * rB >= aB * rA, "BA");
        uint256 a = 1e4 - pF;
        uint256 b = (2e4 - pF) * rA;
        uint256 _c = (aA * rB) - (aB * rA);
        uint256 c = ((_c * 1e4) / (aB + rB)) * rA;

        uint256 d = a * c * 4;
        uint256 e = ((b * b) + d).sqrt();

        return ((e - b) / (2 * a));
    }

    function execute(
        IERC20 token0,
        IERC20 token1,
        uint256 amount0,
        uint256 amount1
    ) public returns (uint256, address) {
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        IUniswapV2Pair pair = _getPair(token0, token1);
        _approve(token0, token1, MAX_INT, MAX_INT);
        (uint reserve0, uint reserve1, ) = pair.getReserves();

        if (address(token0) != pair.token0()) {
            (reserve0, reserve1) = (reserve1, reserve0);
            (amount0, amount1) = (amount1, amount0);
            (token0, token1) = (token1, token0);
        }
        _swap(
            reserve0,
            reserve1,
            address(token0),
            address(token1),
            amount0,
            amount1
        );

        uint lpAmount = _addLiquidity(
            address(token0),
            address(token1),
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );

        _transferLpToken(pair, lpAmount);

        _approve(token0, token1, 0, 0);

        return (lpAmount, address(pair));
    }

    function _approve(
        IERC20 token0,
        IERC20 token1,
        uint amount0,
        uint amount1
    ) internal {
        token0.approve(address(router), amount0);
        token1.approve(address(router), amount1);
    }

    function _swap(
        uint reserve0,
        uint reserve1,
        address token0,
        address token1,
        uint amount0,
        uint amount1
    ) internal {
        (uint swapAmount, bool isAB) = getOptimalSwapAmount(
            amount0,
            amount1,
            reserve0,
            reserve1,
            30
        );

        address[] memory path = new address[](2);
        (path[0], path[1]) = isAB ? (token0, token1) : (token1, token0);

        if (swapAmount > 0)
            router.swapExactTokensForTokens(
                swapAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
    }

    function _addLiquidity(
        address token0,
        address token1,
        uint token0Balance,
        uint token1Balance
    ) internal returns (uint) {
        (, , uint256 lpAmount) = router.addLiquidity(
            token0,
            token1,
            token0Balance,
            token1Balance,
            0,
            0,
            address(this),
            block.timestamp
        );
        return lpAmount;
    }

    function _transferLpToken(IUniswapV2Pair lpToken, uint amount) internal {
        lpToken.transfer(msg.sender, amount);
    }

    function _removeLiquidity() internal {}

    function _getPair(
        IERC20 token0,
        IERC20 token1
    ) internal view returns (IUniswapV2Pair) {
        return
            IUniswapV2Pair(
                IUniswapV2Factory(router.factory()).getPair(
                    address(token0),
                    address(token1)
                )
            );
    }
}
