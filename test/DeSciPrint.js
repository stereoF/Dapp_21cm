const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");


describe("DeSciPrint contract", function () {
    async function deployDeSciPrintFixture() {
        const [owner, address2, editor1, editor2, reviewer1, reviewer2] = await ethers.getSigners();
        const DeSciPrint = await ethers.getContractFactory("DeSciPrint");
        const hardhatDeSciPrint = await DeSciPrint.deploy();
    
        return { hardhatDeSciPrint, owner, address2, editor1, editor2, reviewer1, reviewer2 }
      }

    describe("Peer Review", function() {
        it("Submit", async function () {
            const { hardhatDeSciPrint, address2 } = await loadFixture(
            deployDeSciPrintFixture
            );

            const paperCID = "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyHo";
            const keyInfo = 'test key information'
            const amount = ethers.utils.parseEther('1.5', 'ether')
            
            await hardhatDeSciPrint.connect(address2).submitForReview(paperCID, keyInfo, amount, { value: ethers.utils.parseUnits("10", "ether") });
            expect(await hardhatDeSciPrint.DeSciFileCIDs(0)).to.equal(paperCID);

        });

        
        it("assign the reviewers", async function () {
            const { hardhatDeSciPrint, reviewer1, reviewer2 } = await loadFixture(
                deployDeSciPrintFixture
            );

        });

    });

})

