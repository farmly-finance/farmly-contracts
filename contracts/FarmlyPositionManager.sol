pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./library/FarmlyFullMath.sol";
import "./library/FarmlyStructs.sol";
import "./library/FarmlyTransferHelper.sol";
import "./interfaces/IFarmlyVault.sol";
import "./interfaces/IFarmlyUniV3Executor.sol";
import "./interfaces/IFarmlyPriceConsumer.sol";
import "./interfaces/IFarmlyConfig.sol";
import "./interfaces/IFarmlyUniV3Reader.sol";

contract FarmlyPositionManager {
    struct SlippageProtection {
        uint256 minPositionUSDValue;
        uint256 maxLeverageTolerance; // 1000000 = 1x
    }

    struct VaultInfo {
        IFarmlyVault vault;
        uint debtAmount;
    }

    struct DebtInfo {
        VaultInfo vault;
        uint debtShare;
    }

    struct Position {
        uint uniV3PositionID;
        address owner;
        DebtInfo debt0;
        DebtInfo debt1;
    }

    struct CreatePositionParams {
        IFarmlyUniV3Executor executor;
        uint amount0;
        uint amount1;
        VaultInfo vault0;
        VaultInfo vault1;
        FarmlyStructs.PositionInfo positionInfo;
        FarmlyStructs.SwapInfo swapInfo;
        SlippageProtection slippage;
    }

    struct IncreasePositionParams {
        uint256 positionID;
        IFarmlyUniV3Executor executor;
        uint amount0;
        uint amount1;
        uint debtAmount0;
        uint debtAmount1;
        FarmlyStructs.SwapInfo swapInfo;
        SlippageProtection slippage;
    }

    struct DecreasePositionParams {
        IFarmlyUniV3Executor executor;
        uint positionID;
        uint24 decreasingPercent;
    }

    struct CollectFeesParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
    }

    struct CollectAndIncreaseParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
        uint256 debt0;
        uint256 debt1;
        FarmlyStructs.SwapInfo swapInfo;
        SlippageProtection slippage;
    }

    struct ClosePositionParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
    }

    struct LiquidatePositionParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
    }

    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) public userPositions;

    uint256 public nextPositionID;

    IFarmlyPriceConsumer public farmlyPriceConsumer =
        IFarmlyPriceConsumer(0xF28f90B3c87e075eC5749383DC055dba72835B15);

    IFarmlyConfig public farmlyConfig =
        IFarmlyConfig(0xBc017650E1B704a01e069fa4189fccbf5D767f9C);

    IFarmlyUniV3Reader public farmlyUniV3Reader =
        IFarmlyUniV3Reader(0x8727Ded114fE87E8aEC40E51D29989fD66ccE622);

    constructor() {
        nextPositionID++;
    }

    modifier updateDebtAmount(uint positionID) {
        Position storage position = positions[positionID];
        position.debt0.vault.debtAmount = position
            .debt0
            .vault
            .vault
            .debtShareToDebt(position.debt0.debtShare);
        position.debt1.vault.debtAmount = position
            .debt1
            .vault
            .vault
            .debtShareToDebt(position.debt1.debtShare);
        _;
    }

    function createPosition(CreatePositionParams calldata params) public {
        if (params.amount0 > 0)
            FarmlyTransferHelper.safeTransferFrom(
                params.positionInfo.token0,
                msg.sender,
                address(this),
                params.amount0
            );

        if (params.amount1 > 0)
            FarmlyTransferHelper.safeTransferFrom(
                params.positionInfo.token1,
                msg.sender,
                address(this),
                params.amount1
            );

        uint debtShare0 = params.vault0.vault.borrow(params.vault0.debtAmount);
        uint debtShare1 = params.vault1.vault.borrow(params.vault1.debtAmount);

        FarmlyTransferHelper.safeApprove(
            params.positionInfo.token0,
            address(params.executor),
            params.amount0 + params.vault0.debtAmount
        );

        FarmlyTransferHelper.safeApprove(
            params.positionInfo.token1,
            address(params.executor),
            params.amount1 + params.vault1.debtAmount
        );

        uint256 tokenId = params.executor.execute(
            msg.sender,
            params.amount0 + params.vault0.debtAmount,
            params.amount1 + params.vault1.debtAmount,
            params.positionInfo,
            params.swapInfo
        );

        (, , uint256 positionTotalUSDValue) = farmlyUniV3Reader
            .getPositionUSDValue(tokenId);

        require(
            positionTotalUSDValue > params.slippage.minPositionUSDValue,
            "SLIPPAGE: MIN_USD"
        );

        uint debtUSD = _calcDebtUSD(
            address(params.positionInfo.token0),
            params.vault0.debtAmount,
            address(params.positionInfo.token1),
            params.vault1.debtAmount
        );

        require(
            _calcLeverage(positionTotalUSDValue, debtUSD) <
                params.slippage.maxLeverageTolerance,
            "SLIPPAGE: MAX_LEVERAGE"
        );

        positions[nextPositionID] = Position(
            tokenId,
            msg.sender,
            DebtInfo(params.vault0, debtShare0),
            DebtInfo(params.vault1, debtShare1)
        );

        userPositions[msg.sender].push(nextPositionID);

        nextPositionID++;
    }

    function increasePosition(
        IncreasePositionParams calldata params
    ) public updateDebtAmount(params.positionID) {
        Position storage position = positions[params.positionID];

        params.executor.collect(position.uniV3PositionID, msg.sender);

        (address token0, address token1, , , , ) = farmlyUniV3Reader
            .getPositionInfo(position.uniV3PositionID);

        if (params.amount0 > 0)
            FarmlyTransferHelper.safeTransferFrom(
                token0,
                msg.sender,
                address(this),
                params.amount0
            );
        if (params.amount1 > 0)
            FarmlyTransferHelper.safeTransferFrom(
                token1,
                msg.sender,
                address(this),
                params.amount1
            );

        uint debtShare0 = position.debt0.vault.vault.borrow(params.debtAmount0);
        uint debtShare1 = position.debt1.vault.vault.borrow(params.debtAmount1);

        FarmlyTransferHelper.safeApprove(
            token0,
            address(params.executor),
            params.amount0 + params.debtAmount0
        );
        FarmlyTransferHelper.safeApprove(
            token1,
            address(params.executor),
            params.amount1 + params.debtAmount1
        );

        params.executor.increase(
            position.uniV3PositionID,
            msg.sender,
            params.amount0 + params.debtAmount0,
            params.amount1 + params.debtAmount1,
            params.swapInfo
        );

        (, , uint256 positionTotalUSDValue) = farmlyUniV3Reader
            .getPositionUSDValue(position.uniV3PositionID);

        require(
            positionTotalUSDValue > params.slippage.minPositionUSDValue,
            "SLIPPAGE: MIN_USD"
        );

        uint debtUSD = _calcDebtUSD(
            token0,
            position.debt0.vault.debtAmount + params.debtAmount0,
            token1,
            position.debt1.vault.debtAmount + params.debtAmount1
        );

        require(
            _calcLeverage(positionTotalUSDValue, debtUSD) <
                params.slippage.maxLeverageTolerance,
            "SLIPPAGE: MAX_LEVERAGE"
        );

        position.debt0.debtShare += debtShare0;
        position.debt1.debtShare += debtShare1;
        position.debt0.vault.debtAmount += params.debtAmount0;
        position.debt1.vault.debtAmount += params.debtAmount1;
    }

    function decreasePosition(
        DecreasePositionParams calldata params
    ) public updateDebtAmount(params.positionID) {
        Position storage position = positions[params.positionID];

        params.executor.collect(position.uniV3PositionID, msg.sender);

        uint256 debt0 = position.debt0.vault.vault.debtShareToDebt(
            (position.debt0.debtShare * params.decreasingPercent) / 1000000
        );
        uint256 debt1 = position.debt1.vault.vault.debtShareToDebt(
            (position.debt1.debtShare * params.decreasingPercent) / 1000000
        );

        (
            uint256 amount0,
            uint256 amount1,
            ,
            address token0,
            address token1,

        ) = params.executor.decrease(
                position.uniV3PositionID,
                params.decreasingPercent,
                debt0,
                debt1
            );

        FarmlyTransferHelper.safeApprove(
            token0,
            address(position.debt0.vault.vault),
            amount0
        );

        FarmlyTransferHelper.safeApprove(
            token1,
            address(position.debt1.vault.vault),
            amount1
        );

        position.debt0.vault.vault.close(
            (position.debt0.debtShare * params.decreasingPercent) / 1000000
        );
        position.debt1.vault.vault.close(
            (position.debt1.debtShare * params.decreasingPercent) / 1000000
        );

        FarmlyTransferHelper.safeTransfer(token0, msg.sender, amount0 - debt0);
        FarmlyTransferHelper.safeTransfer(token1, msg.sender, amount1 - debt1);

        position.debt0.debtShare -=
            (position.debt0.debtShare * params.decreasingPercent) /
            1000000;
        position.debt1.debtShare -=
            (position.debt1.debtShare * params.decreasingPercent) /
            1000000;
        position.debt0.vault.debtAmount -= debt0;
        position.debt1.vault.debtAmount -= debt1;
    }

    function collectFees(CollectFeesParams calldata params) public {
        Position storage position = positions[params.positionID];
        params.executor.collect(position.uniV3PositionID, msg.sender);
    }

    function collectAndIncrease(
        CollectAndIncreaseParams calldata params
    ) public updateDebtAmount(params.positionID) {
        Position storage position = positions[params.positionID];
        (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1
        ) = params.executor.collect(position.uniV3PositionID, address(this));

        uint debtShare0 = position.debt0.vault.vault.borrow(params.debt0);
        uint debtShare1 = position.debt1.vault.vault.borrow(params.debt1);

        FarmlyTransferHelper.safeApprove(
            token0,
            address(params.executor),
            amount0 + params.debt0
        );
        FarmlyTransferHelper.safeApprove(
            token1,
            address(params.executor),
            amount1 + params.debt1
        );

        params.executor.increase(
            position.uniV3PositionID,
            msg.sender,
            amount0 + params.debt0,
            amount1 + params.debt1,
            params.swapInfo
        );

        (, , uint256 positionTotalUSDValue) = farmlyUniV3Reader
            .getPositionUSDValue(position.uniV3PositionID);

        require(
            positionTotalUSDValue > params.slippage.minPositionUSDValue,
            "SLIPPAGE: MIN_USD"
        );

        uint debtUSD = _calcDebtUSD(
            token0,
            position.debt0.vault.debtAmount + params.debt0,
            token1,
            position.debt1.vault.debtAmount + params.debt1
        );

        require(
            _calcLeverage(positionTotalUSDValue, debtUSD) <
                params.slippage.maxLeverageTolerance,
            "SLIPPAGE: MAX_LEVERAGE"
        );

        position.debt0.debtShare += debtShare0;
        position.debt1.debtShare += debtShare1;
        position.debt0.vault.debtAmount += params.debt0;
        position.debt1.vault.debtAmount += params.debt1;
    }

    function closePosition(
        ClosePositionParams calldata params
    ) public updateDebtAmount(params.positionID) {
        Position storage position = positions[params.positionID];

        params.executor.collect(position.uniV3PositionID, msg.sender);

        uint256 debt0 = position.debt0.vault.debtAmount;
        uint256 debt1 = position.debt1.vault.debtAmount;

        (
            uint256 amount0,
            uint256 amount1,
            ,
            address token0,
            address token1,

        ) = params.executor.close(position.uniV3PositionID, debt0, debt1);

        FarmlyTransferHelper.safeApprove(
            token0,
            address(position.debt0.vault.vault),
            amount0
        );

        FarmlyTransferHelper.safeApprove(
            token1,
            address(position.debt1.vault.vault),
            amount1
        );

        position.debt0.vault.vault.close(position.debt0.debtShare);
        position.debt1.vault.vault.close(position.debt1.debtShare);

        FarmlyTransferHelper.safeTransfer(token0, msg.sender, amount0 - debt0);
        FarmlyTransferHelper.safeTransfer(token1, msg.sender, amount1 - debt1);

        position.debt0.debtShare = 0;
        position.debt1.debtShare = 0;
        position.debt0.vault.debtAmount = 0;
        position.debt1.vault.debtAmount = 0;
    }

    function liquidatePosition(
        LiquidatePositionParams calldata params
    ) public updateDebtAmount(params.positionID) {
        require(getFlyScore(params.positionID) >= 10000, "Can't liquidate");

        Position storage position = positions[params.positionID];

        params.executor.collect(position.uniV3PositionID, msg.sender);

        uint256 debt0 = position.debt0.vault.debtAmount;
        uint256 debt1 = position.debt1.vault.debtAmount;

        (
            uint256 amount0,
            uint256 amount1,
            ,
            address token0,
            address token1,

        ) = params.executor.close(position.uniV3PositionID, debt0, debt1);

        FarmlyTransferHelper.safeApprove(
            token0,
            address(position.debt0.vault.vault),
            amount0
        );

        FarmlyTransferHelper.safeApprove(
            token1,
            address(position.debt1.vault.vault),
            amount1
        );

        position.debt0.vault.vault.close(position.debt0.debtShare);
        position.debt1.vault.vault.close(position.debt1.debtShare);

        FarmlyTransferHelper.safeTransfer(token0, msg.sender, amount0 - debt0);
        FarmlyTransferHelper.safeTransfer(token1, msg.sender, amount1 - debt1);

        position.debt0.debtShare = 0;
        position.debt1.debtShare = 0;
        position.debt0.vault.debtAmount = 0;
        position.debt1.vault.debtAmount = 0;
    }

    function getPositionUSDValue(
        uint256 positionID
    )
        public
        view
        returns (uint256 token0USD, uint256 token1USD, uint256 totalUSD)
    {
        Position memory position = positions[positionID];
        (token0USD, token1USD, totalUSD) = farmlyUniV3Reader
            .getPositionUSDValue(position.uniV3PositionID);
    }

    function getDebtRatio(
        uint256 positionID
    ) public view returns (uint256 debtRatio) {
        (, , uint256 debtUSD) = getDebtUSDValue(positionID);
        (, , uint256 totalUSD) = getPositionUSDValue(positionID);

        debtRatio = FarmlyFullMath.mulDiv(debtUSD, 1e6, totalUSD);
    }

    function getFlyScore(
        uint256 positionID
    ) public view returns (uint256 flyScrore) {
        uint256 debtRatio = getDebtRatio(positionID);
        flyScrore = FarmlyFullMath.mulDiv(
            debtRatio,
            10000,
            farmlyConfig.liquidationThreshold()
        );
    }

    function getDebtUSDValue(
        uint256 positionID
    )
        public
        view
        returns (uint256 debt0USD, uint256 debt1USD, uint256 debtUSD)
    {
        Position memory position = positions[positionID];
        (address token0, address token1, , , , ) = farmlyUniV3Reader
            .getPositionInfo(position.uniV3PositionID);
        uint debt0 = position.debt0.vault.vault.debtShareToDebt(
            position.debt0.debtShare
        );
        uint debt1 = position.debt1.vault.vault.debtShareToDebt(
            position.debt1.debtShare
        );
        debt0USD = farmlyPriceConsumer.calcUSDValue(token0, debt0);
        debt1USD = farmlyPriceConsumer.calcUSDValue(token1, debt1);
        debtUSD = debt0USD + debt1USD;
    }

    function getCurrentLeverage(
        uint256 positionID
    ) public view returns (uint256 leverage) {
        (, , uint256 totalUSD) = getPositionUSDValue(positionID);
        (, , uint256 debtUSD) = getDebtUSDValue(positionID);

        leverage = _calcLeverage(totalUSD, debtUSD);
    }

    function getDebtRatios(
        uint256 positionID
    ) public view returns (uint256 debtRatio0, uint256 debtRatio1) {
        (uint256 debt0, uint256 debt1, uint256 debtUSD) = getDebtUSDValue(
            positionID
        );

        debtRatio0 = FarmlyFullMath.mulDiv(debt0, 1000000, debtUSD);
        debtRatio1 = FarmlyFullMath.mulDiv(debt1, 1000000, debtUSD);
    }

    function getUserPositions(
        address user
    ) public view returns (uint256[] memory) {
        return userPositions[user];
    }

    function _calcLeverage(
        uint256 totalUSD,
        uint256 debtUSD
    ) internal pure returns (uint256 leverage) {
        leverage = FarmlyFullMath.mulDiv(totalUSD, 1000000, totalUSD - debtUSD);
    }

    function _calcDebtUSD(
        address token0,
        uint debt0,
        address token1,
        uint debt1
    ) internal view returns (uint debtUSD) {
        debtUSD =
            farmlyPriceConsumer.calcUSDValue(token0, debt0) +
            farmlyPriceConsumer.calcUSDValue(token1, debt1);
    }
}
