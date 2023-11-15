const { ethers, network } = require("hardhat");

module.exports = async (hre) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    const farmlyInterestModel = await deploy("FarmlyInterestModel2", {
        from: deployer,
        log: true,
        args: [],
        waitConfirmations: 2,
        contract: "FarmlyInterestModel"
    });

    const farmlyConfig = await hre.deployments.get('FarmlyConfig');

    const farmlyVault = await deploy("FarmlyVault2", {
        from: deployer,
        log: true,
        args: [farmlyConfig.address, process.env.VAULT_TOKEN_2, "Farmly ETH Interest Bearing", "flyETH"],
        waitConfirmations: 2,
        contract: "FarmlyVault"
    });

    if (farmlyVault.newlyDeployed)
        await hre.deployments.execute('FarmlyConfig', { from: deployer }, 'setVaultInterestModel', farmlyVault.address, farmlyInterestModel.address);



};

module.exports.tags = ["all", "vaults"];