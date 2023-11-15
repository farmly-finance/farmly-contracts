const { network } = require("hardhat");
require('dotenv').config();

module.exports = async (hre) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    const farmlyPriceConsumer = await deploy("FarmlyPriceConsumer", {
        from: deployer,
        log: true,
        args: [],
        waitConfirmations: 2,
    });

    const farmlyConfig = await deploy("FarmlyConfig", {
        from: deployer,
        log: true,
        args: [],
        waitConfirmations: 2,
    });

    const farmlyUniV3Reader = await deploy("FarmlyUniV3Reader", {
        from: deployer,
        log: true,
        args: [process.env.NONFUNGIBLE_POSITION_MANAGER, process.env.UNISWAP_V3_FACTORY, (await hre.deployments.get('FarmlyPriceConsumer')).address],
        waitConfirmations: 2,
    });

};

module.exports.tags = ["all", "initial"];