pragma solidity >=0.5.0;
import "./uniV3Executor/IFarmlyUniV3ExecutorImmutables.sol";

/// @title The interface for the Farmly Uniswap V3 Executor
/// @notice Functions for the management of positions on Uniswap V3.
/// @dev Uniswap V3 position NFTs are stored in this contract.
/// It can only be called by the Farmly Position Manager contract.
/// It acts as a bridge between Uniswap V3 and Farmly Finance.
interface IFarmlyUniV3Executor is IFarmlyUniV3ExecutorImmutables {

}
