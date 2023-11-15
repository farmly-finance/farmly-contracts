const { network } = require("hardhat");
require('dotenv').config();

module.exports = async (hre) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    const farmlyUniV3Executor = await deploy("FarmlyUniV3Executor", {
        from: deployer,
        log: true,
        args: [
            process.env.NONFUNGIBLE_POSITION_MANAGER,
            process.env.UNISWAP_V3_ROUTER,
            process.env.UNISWAP_V3_FACTORY,
            (await hre.deployments.get('FarmlyConfig')).address,
            (await hre.deployments.get('FarmlyUniV3Reader')).address
        ],
        waitConfirmations: 2,
    });

    const farmlyPositionManager = await deploy("FarmlyPositionManager", {
        from: deployer,
        log: true,
        args: [
            (await hre.deployments.get('FarmlyPriceConsumer')).address,
            (await hre.deployments.get('FarmlyConfig')).address,
            (await hre.deployments.get('FarmlyUniV3Reader')).address
        ],
        waitConfirmations: 2,
    });

};

module.exports.tags = ["all", "others"];