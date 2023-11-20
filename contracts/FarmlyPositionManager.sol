pragma solidity >=0.5.0;

import "./interfaces/IFarmlyPositionManager.sol";

import "./libraries/FarmlyFullMath.sol";
import "./libraries/FarmlyTransferHelper.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FarmlyPositionManager is
    IFarmlyPositionManager,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    /// @inheritdoc IFarmlyPositionManagerImmutables
    IFarmlyPriceConsumer public override farmlyPriceConsumer;
    /// @inheritdoc IFarmlyPositionManagerImmutables
    IFarmlyConfig public override farmlyConfig;
    /// @inheritdoc IFarmlyPositionManagerImmutables
    IFarmlyUniV3Reader public override farmlyUniV3Reader;
    /// @inheritdoc IFarmlyPositionManagerState
    mapping(uint256 => Position) public override positions;
    /// @inheritdoc IFarmlyPositionManagerState
    uint256[] public override activePositions;
    /// @inheritdoc IFarmlyPositionManagerState
    uint256 public override nextPositionID;
    /// IFarmlyPositionManagerState userPositions state
    mapping(address => uint256[]) private _userPositions;
    /// Indexes of active positions in state, positionID => index
    mapping(uint256 => uint256) private _activePositionsIndex;
    /// Maximum usable integer value
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    /// Denominator for ratios
    uint256 constant RATIO_DENOMINATOR = 0xf4240; // 1e6
    /// Denominator for flyScore
    uint256 constant FLYSCORE_DENOMINATOR = 0x2710; // 1e4

    constructor(
        IFarmlyPriceConsumer _farmlyPriceConsumer,
        IFarmlyConfig _farmlyConfig,
        IFarmlyUniV3Reader _farmlyUniV3Reader
    ) {
        farmlyPriceConsumer = _farmlyPriceConsumer;
        farmlyConfig = _farmlyConfig;
        farmlyUniV3Reader = _farmlyUniV3Reader;
        nextPositionID++;
    }

    /// @inheritdoc IFarmlyPositionManagerState
    function userPositions(
        address user
    ) public view override returns (uint256[] memory) {
        return _userPositions[user];
    }

    /// @inheritdoc IFarmlyPositionManagerDerivedState
    function getActivePositionsLength() public view override returns (uint256) {
        return activePositions.length;
    }

    /// @inheritdoc IFarmlyPositionManagerDerivedState
    function getPositionUSDValue(
        uint256 positionID
    )
        public
        view
        override
        returns (uint256 token0USD, uint256 token1USD, uint256 totalUSD)
    {
        Position memory position = positions[positionID];

        (token0USD, token1USD, totalUSD) = farmlyUniV3Reader
            .getPositionUSDValue(position.uniV3PositionID);
    }

    /// @inheritdoc IFarmlyPositionManagerDerivedState
    function getDebtRatio(
        uint256 positionID
    ) public view override returns (uint256 debtRatio) {
        (, , uint256 debtUSD) = getDebtUSDValue(positionID);
        (, , uint256 totalUSD) = getPositionUSDValue(positionID);

        debtRatio = FarmlyFullMath.mulDiv(debtUSD, RATIO_DENOMINATOR, totalUSD);
    }

    /// @inheritdoc IFarmlyPositionManagerDerivedState
    function getFlyScore(
        uint256 positionID
    ) public view override returns (uint256 flyScore) {
        uint256 debtRatio = getDebtRatio(positionID);

        flyScore = FarmlyFullMath.mulDiv(
            debtRatio,
            10000,
            farmlyConfig.liquidationThreshold()
        );
    }

    /// @inheritdoc IFarmlyPositionManagerDerivedState
    function getDebtUSDValue(
        uint256 positionID
    )
        public
        view
        override
        returns (uint256 debt0USD, uint256 debt1USD, uint256 debtUSD)
    {
        Position memory position = positions[positionID];

        (address token0, address token1, , , , ) = farmlyUniV3Reader
            .getPositionInfo(position.uniV3PositionID);

        uint debt0 = position.debt0.vault.debtShareToDebt(
            position.debt0.debtShare
        );
        uint debt1 = position.debt1.vault.debtShareToDebt(
            position.debt1.debtShare
        );

        debt0USD = farmlyPriceConsumer.calcUSDValue(token0, debt0);
        debt1USD = farmlyPriceConsumer.calcUSDValue(token1, debt1);

        debtUSD = debt0USD + debt1USD;
    }

    /// @inheritdoc IFarmlyPositionManagerDerivedState
    function getCurrentLeverage(
        uint256 positionID
    ) public view override returns (uint256 leverage) {
        (, , uint256 totalUSD) = getPositionUSDValue(positionID);
        (, , uint256 debtUSD) = getDebtUSDValue(positionID);

        leverage = _calcLeverage(totalUSD, debtUSD);
    }

    /// @inheritdoc IFarmlyPositionManagerDerivedState
    function getDebtRatios(
        uint256 positionID
    ) public view override returns (uint256 debtRatio0, uint256 debtRatio1) {
        (uint256 debt0, uint256 debt1, uint256 debtUSD) = getDebtUSDValue(
            positionID
        );

        debtRatio0 = FarmlyFullMath.mulDiv(debt0, RATIO_DENOMINATOR, debtUSD);
        debtRatio1 = FarmlyFullMath.mulDiv(debt1, RATIO_DENOMINATOR, debtUSD);
    }

    /// @inheritdoc IFarmlyPositionManagerActions
    function createPosition(
        CreatePositionParams calldata params
    ) public override whenNotPaused nonReentrant {
        if (params.amount0 > 0)
            FarmlyTransferHelper.safeTransferFrom(
                params.positionInfo.token0,
                msg.sender,
                address(params.executor),
                params.amount0
            );

        if (params.amount1 > 0)
            FarmlyTransferHelper.safeTransferFrom(
                params.positionInfo.token1,
                msg.sender,
                address(params.executor),
                params.amount1
            );

        uint debtShare0 = params.vault0.vault.borrow(
            params.vault0.debtAmount,
            address(params.executor)
        );
        uint debtShare1 = params.vault1.vault.borrow(
            params.vault1.debtAmount,
            address(params.executor)
        );

        uint256 tokenId = params.executor.execute(
            msg.sender,
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
            DebtInfo(params.vault0.vault, debtShare0),
            DebtInfo(params.vault1.vault, debtShare1)
        );

        emit PositionCreated(
            tokenId,
            nextPositionID,
            params.positionInfo.token0,
            params.positionInfo.token1,
            params.amount0,
            params.amount1,
            params.vault0.debtAmount,
            params.vault1.debtAmount
        );

        _addPosition();
    }

    /// @inheritdoc IFarmlyPositionManagerActions
    function increasePosition(
        IncreasePositionParams calldata params
    ) public override whenNotPaused nonReentrant {
        Position storage position = positions[params.positionID];

        require(msg.sender == position.owner, "NOT_OWNER");

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

        uint debtShare0 = position.debt0.vault.borrow(
            params.debtAmount0,
            address(this)
        );
        uint debtShare1 = position.debt1.vault.borrow(
            params.debtAmount1,
            address(this)
        );

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
            _debtShareToDebt(position.debt0) + params.debtAmount0,
            token1,
            _debtShareToDebt(position.debt1) + params.debtAmount1
        );

        require(
            _calcLeverage(positionTotalUSDValue, debtUSD) <
                params.slippage.maxLeverageTolerance,
            "SLIPPAGE: MAX_LEVERAGE"
        );

        position.debt0.debtShare += debtShare0;
        position.debt1.debtShare += debtShare1;

        emit PositionIncreased(
            position.uniV3PositionID,
            params.positionID,
            token0,
            token1,
            params.amount0,
            params.amount1,
            params.debtAmount0,
            params.debtAmount1
        );
    }

    /// @inheritdoc IFarmlyPositionManagerActions
    function decreasePosition(
        DecreasePositionParams calldata params
    ) public override nonReentrant {
        Position storage position = positions[params.positionID];

        require(msg.sender == position.owner, "NOT_OWNER");

        params.executor.collect(position.uniV3PositionID, msg.sender);

        uint256 debt0 = position.debt0.vault.debtShareToDebt(
            (position.debt0.debtShare * params.decreasingPercent) /
                RATIO_DENOMINATOR
        );
        uint256 debt1 = position.debt1.vault.debtShareToDebt(
            (position.debt1.debtShare * params.decreasingPercent) /
                RATIO_DENOMINATOR
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
            address(position.debt0.vault),
            amount0
        );
        FarmlyTransferHelper.safeApprove(
            token1,
            address(position.debt1.vault),
            amount1
        );

        position.debt0.vault.repay(
            (position.debt0.debtShare * params.decreasingPercent) /
                RATIO_DENOMINATOR
        );
        position.debt1.vault.repay(
            (position.debt1.debtShare * params.decreasingPercent) /
                RATIO_DENOMINATOR
        );

        FarmlyTransferHelper.safeTransfer(token0, msg.sender, amount0 - debt0);
        FarmlyTransferHelper.safeTransfer(token1, msg.sender, amount1 - debt1);

        position.debt0.debtShare -=
            (position.debt0.debtShare * params.decreasingPercent) /
            RATIO_DENOMINATOR;
        position.debt1.debtShare -=
            (position.debt1.debtShare * params.decreasingPercent) /
            RATIO_DENOMINATOR;

        if (params.decreasingPercent == RATIO_DENOMINATOR)
            _removePosition(params.positionID);

        emit PositionDecreased(
            position.uniV3PositionID,
            params.positionID,
            token0,
            token1,
            amount0,
            amount1,
            debt0,
            debt1
        );
    }

    /// @inheritdoc IFarmlyPositionManagerActions
    function collectFees(
        CollectFeesParams calldata params
    ) public override nonReentrant {
        Position storage position = positions[params.positionID];

        require(msg.sender == position.owner, "NOT_OWNER");

        (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1
        ) = params.executor.collect(position.uniV3PositionID, msg.sender);

        emit FeesCollected(
            position.uniV3PositionID,
            params.positionID,
            token0,
            token1,
            amount0,
            amount1
        );
    }

    /// @inheritdoc IFarmlyPositionManagerActions
    function collectAndIncrease(
        CollectAndIncreaseParams calldata params
    ) public override whenNotPaused nonReentrant {
        Position storage position = positions[params.positionID];

        require(msg.sender == position.owner, "NOT_OWNER");

        (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1
        ) = params.executor.collect(position.uniV3PositionID, address(this));

        uint debtShare0 = position.debt0.vault.borrow(
            params.debt0,
            address(this)
        );
        uint debtShare1 = position.debt1.vault.borrow(
            params.debt1,
            address(this)
        );

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
            _debtShareToDebt(position.debt0) + params.debt0,
            token1,
            _debtShareToDebt(position.debt1) + params.debt1
        );

        require(
            _calcLeverage(positionTotalUSDValue, debtUSD) <
                params.slippage.maxLeverageTolerance,
            "SLIPPAGE: MAX_LEVERAGE"
        );

        position.debt0.debtShare += debtShare0;
        position.debt1.debtShare += debtShare1;

        emit FeesCollectedAndPositionIncreased(
            position.uniV3PositionID,
            params.positionID,
            amount0,
            amount1,
            params.debt0,
            params.debt1
        );
    }

    /// @inheritdoc IFarmlyPositionManagerActions
    function closePosition(
        ClosePositionParams calldata params
    ) public override nonReentrant {
        Position storage position = positions[params.positionID];

        require(msg.sender == position.owner, "NOT_OWNER");

        params.executor.collect(position.uniV3PositionID, msg.sender);

        uint256 debt0 = _debtShareToDebt(position.debt0);
        uint256 debt1 = _debtShareToDebt(position.debt1);

        (
            uint256 amount0,
            uint256 amount1,
            ,
            address token0,
            address token1,

        ) = params.executor.close(position.uniV3PositionID, debt0, debt1);

        FarmlyTransferHelper.safeApprove(
            token0,
            address(position.debt0.vault),
            amount0
        );
        FarmlyTransferHelper.safeApprove(
            token1,
            address(position.debt1.vault),
            amount1
        );

        position.debt0.vault.repay(position.debt0.debtShare);
        position.debt1.vault.repay(position.debt1.debtShare);

        FarmlyTransferHelper.safeTransfer(token0, msg.sender, amount0 - debt0);
        FarmlyTransferHelper.safeTransfer(token1, msg.sender, amount1 - debt1);

        position.debt0.debtShare = 0;
        position.debt1.debtShare = 0;

        _removePosition(params.positionID);

        emit PositionClosed(
            position.uniV3PositionID,
            params.positionID,
            token0,
            token1,
            amount0,
            amount1,
            debt0,
            debt1
        );
    }

    /// @inheritdoc IFarmlyPositionManagerActions
    function liquidatePosition(
        LiquidatePositionParams calldata params
    ) public override nonReentrant {
        require(getFlyScore(params.positionID) >= 10000, "CANT_LIQUIDATE");

        Position storage position = positions[params.positionID];

        params.executor.collect(position.uniV3PositionID, msg.sender);

        uint256 debt0 = _debtShareToDebt(position.debt0);
        uint256 debt1 = _debtShareToDebt(position.debt1);

        (
            uint256 amount0,
            uint256 amount1,
            ,
            address token0,
            address token1,

        ) = params.executor.close(position.uniV3PositionID, debt0, debt1);

        FarmlyTransferHelper.safeApprove(
            token0,
            address(position.debt0.vault),
            amount0
        );
        FarmlyTransferHelper.safeApprove(
            token1,
            address(position.debt1.vault),
            amount1
        );

        position.debt0.vault.repay(position.debt0.debtShare);
        position.debt1.vault.repay(position.debt1.debtShare);

        FarmlyTransferHelper.safeTransfer(token0, msg.sender, amount0 - debt0);
        FarmlyTransferHelper.safeTransfer(token1, msg.sender, amount1 - debt1);

        position.debt0.debtShare = 0;
        position.debt1.debtShare = 0;

        _removePosition(params.positionID);

        emit PositionLiquidated(
            position.uniV3PositionID,
            params.positionID,
            token0,
            token1,
            amount0,
            amount1,
            debt0,
            debt1
        );
    }

    /// @inheritdoc IFarmlyPositionManagerOwnerActions
    function pause() public override onlyOwner {
        _pause();
    }

    /// @inheritdoc IFarmlyPositionManagerOwnerActions
    function unpause() public override onlyOwner {
        _unpause();
    }

    function _calcLeverage(
        uint256 totalUSD,
        uint256 debtUSD
    ) internal pure returns (uint256 leverage) {
        leverage = FarmlyFullMath.mulDiv(
            totalUSD,
            RATIO_DENOMINATOR,
            totalUSD - debtUSD
        );
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

    function _debtShareToDebt(
        DebtInfo memory debt
    ) internal view returns (uint256 debtAmount) {
        debtAmount = debt.vault.debtShareToDebt(debt.debtShare);
    }

    function _addPosition() internal {
        _userPositions[msg.sender].push(nextPositionID);
        _activePositionsIndex[nextPositionID] = activePositions.length;
        activePositions.push(nextPositionID);
        nextPositionID++;
    }

    function _removePosition(uint256 positionID) internal {
        uint256 lastPositionIndex = activePositions.length - 1;
        uint256 positionIndex = _activePositionsIndex[positionID];

        uint256 lastPositionID = activePositions[lastPositionIndex];

        activePositions[positionIndex] = lastPositionID;
        _activePositionsIndex[lastPositionID] = positionIndex;

        delete _activePositionsIndex[positionID];
        activePositions.pop();
    }
}
