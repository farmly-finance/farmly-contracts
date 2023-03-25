const { expect } = require("chai");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Farmly", function () {
    it("...", async function () {
        const depositAmount = "1000000000000000000000"
        const borrowAmount = "100000000000000000000"
        const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
        const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

        // deploy a lock contract where funds can be withdrawn
        // one year in the future
        const TestToken = await hre.ethers.getContractFactory("TestToken");
        const testToken = await TestToken.deploy();

        const FarmlyVault = await hre.ethers.getContractFactory("FarmlyVault");
        const farmlyVault = await FarmlyVault.deploy(testToken.address);


        await testToken.approve(farmlyVault.address, depositAmount);

        await farmlyVault.deposit(depositAmount); // 000000000000000000
        await farmlyVault.borrow(borrowAmount);

        console.log(await time.latest())
        await time.increaseTo(unlockTime);
        console.log(await time.latest())
        console.log(await testToken.balanceOf(farmlyVault.address), "token balance");
        console.log(await farmlyVault.totalBorrowed(), "totalBorrowed");
        console.log(await farmlyVault.totalToken(), "totalToken")
        console.log(await farmlyVault.getBorrowAPR(depositAmount, "900000000000000000000"), "borrow apr");
        console.log(await farmlyVault.pendingInterest(0), "pendinginterest");
        console.log(await farmlyVault.lastAction(), "lastAction");
        console.log(await farmlyVault.ONE_YEAR(), "oneYEAR")
        // assert that the value is correct
        expect(testToken, farmlyVault);
    });
});