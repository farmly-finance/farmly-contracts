const { expect } = require("chai");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Farmly", function () {
    it("...", async function () {
        const [owner] = await ethers.getSigners();
        // 000000000000000000
        const depositAmount = "100000000000000000000" // 100
        const borrowAmount = "20000000000000000000" // 20

        const ONE_YEAR = 365 * 24 * 60 * 60;
        const unlockTime = (await time.latest()) + ONE_YEAR;

        const TestToken = await hre.ethers.getContractFactory("TestToken");
        const testToken = await TestToken.deploy();

        const FarmlyVault = await hre.ethers.getContractFactory("FarmlyVault");
        const farmlyVault = await FarmlyVault.deploy(testToken.address);


        const FarmlyConfig = await hre.ethers.getContractFactory("FarmlyConfig");
        const farmlyConfig = await FarmlyConfig.deploy();

        console.log("MAKE DEPOSIT")
        console.log("------------------------------------------")
        console.log(await testToken.balanceOf(owner.address), "account eth balance")
        await testToken.approve(farmlyVault.address, depositAmount)
        await farmlyVault.deposit(depositAmount)
        console.log(await testToken.balanceOf(farmlyVault.address), "vault eth balance")
        console.log(await testToken.balanceOf(owner.address), "account eth balance")
        console.log("------------------------------------------")
        console.log("------------------------------------------")


        console.log("GET DEBT")
        console.log("------------------------------------------")
        await farmlyVault.borrow(borrowAmount)
        console.log(await farmlyVault.totalBorrowed(), "total borrowed");
        console.log(await testToken.balanceOf(farmlyVault.address), "vault eth balance")
        console.log(await testToken.balanceOf(owner.address), "account eth balance")
        console.log("------------------------------------------")
        console.log("------------------------------------------")

        console.log("INCREASE TIME (1 YEAR)")
        console.log("------------------------------------------")
        await time.increase(ONE_YEAR)
        console.log(await farmlyVault.pendingInterest(0), "pending interest");
        const borrowAPRYearly = (await farmlyVault.getBorrowAPR(borrowAmount, depositAmount) / 100e18) * ONE_YEAR;
        console.log("------------------------------------------")
        console.log("------------------------------------------")


        console.log("CLOSE DEBT")
        console.log("------------------------------------------")
        await testToken.approve(farmlyVault.address, depositAmount)
        console.log(await farmlyVault.totalBorrowed(), "total borrowed");
        console.log((await farmlyVault.close()).hash, "repay")
        console.log(await farmlyVault.totalBorrowed(), "total borrowed");
        console.log(await testToken.balanceOf(farmlyVault.address), "vault eth balance")
        console.log(await testToken.balanceOf(owner.address), "account eth balance")
        console.log("------------------------------------------")
        console.log("------------------------------------------")

        console.log("WITHDRAW ETH")
        console.log("------------------------------------------")
        await farmlyVault.withdraw(depositAmount);
        console.log(await testToken.balanceOf(farmlyVault.address), "vault eth balance")
        console.log(await testToken.balanceOf(owner.address), "account eth balance")
        // assert that the value is correct
        expect(testToken, farmlyVault);
    });
});