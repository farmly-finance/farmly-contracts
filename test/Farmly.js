const { expect } = require("chai");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Farmly", function () {
    it("...", async function () {
        const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
        const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

        const TestToken = await hre.ethers.getContractFactory("TestToken");
        const testToken = await TestToken.deploy();

        const FarmlyVault = await hre.ethers.getContractFactory("FarmlyVault");
        const farmlyVault = await FarmlyVault.deploy(testToken.address);


        const FarmlyConfig = await hre.ethers.getContractFactory("FarmlyConfig");
        const farmlyConfig = await FarmlyConfig.deploy();


        console.log(await farmlyConfig.getBorrowAPR(99, 100))
        console.log(await farmlyConfig.getBorrowAPR(99, 100) / 100e18)

        // assert that the value is correct
        expect(testToken, farmlyVault);
    });
});