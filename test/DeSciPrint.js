const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");


describe("DeSciPrint contract", function () {
    async function deployDeSciPrintFixture() {
        const [owner, address1, address2, editor1, editor2, reviewer1, reviewer2] = await ethers.getSigners();
        const DeSciPrint = await ethers.getContractFactory("DeSciPrint");
        const hardhatDeSciPrint = await DeSciPrint.deploy();
    
        return { hardhatDeSciPrint, owner, address1, address2, editor1, editor2, reviewer1, reviewer2 };
      };

      async function submitPrintsFixture() {
        const [owner, address1, address2, editor1, editor2, reviewer1, reviewer2] = await ethers.getSigners();
        const DeSciPrint = await ethers.getContractFactory("DeSciPrint");
        const hardhatDeSciPrint = await DeSciPrint.deploy();

        const minGasCost = await hardhatDeSciPrint.minGasCost();
        await hardhatDeSciPrint.pushEditors([editor1.address, editor2.address]);

        const paper1 = {
            paperCID: "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyHo",
            keyInfo: 'paper 1',
            amount: ethers.utils.parseEther('1.5', 'ether')
        };
        await hardhatDeSciPrint.connect(address1).submitForReview(paper1.paperCID, paper1.keyInfo, paper1.amount, 
            { value: paper1.amount.add(minGasCost) });

        const paper2 = {
            paperCID: "QmakBV63npN4DLpYheAq9jpn9yLqsGi3caSUtJ8GCUQ27H",
            keyInfo: 'paper 2',
            amount: ethers.utils.parseEther('1.7', 'ether')
        };
        const blockTime = Date.now() + 15;
        await time.setNextBlockTimestamp(blockTime);
        await hardhatDeSciPrint.connect(address2).submitForReview(paper2.paperCID, paper2.keyInfo, paper2.amount, 
            { value: paper2.amount.add(minGasCost) });

    
        return { hardhatDeSciPrint, owner, address1, address2, editor1, editor2, 
            reviewer1, reviewer2, paper1, paper2, minGasCost, blockTime };
      };

    describe("Management", function() {
        it("Set minGasCost", async function () {
            const { hardhatDeSciPrint } = await loadFixture(
                deployDeSciPrintFixture
            );

            const minGasCost = ethers.utils.parseEther('0.2', 'ether');
            await hardhatDeSciPrint.setMinGasCost(minGasCost);
            
            expect(await hardhatDeSciPrint.minGasCost()).to.equal(ethers.utils.parseEther('0.2', 'ether'));

        });

    });


    describe("Peer Review", function() {

        it("The balance of contract should equal to the authors paid", async function () {
            const { hardhatDeSciPrint, minGasCost, paper1, paper2 } = await loadFixture(
                submitPrintsFixture
            );

            totalAmount = minGasCost.mul(2).add(paper1.amount).add(paper2.amount);
            expect(await hardhatDeSciPrint.getBalance()).to.equal(totalAmount);

        });

        it("The prints info should be as same as the info submitted", async function () {
            const { hardhatDeSciPrint, address2, paper2, blockTime } = await loadFixture(
                submitPrintsFixture
            );

            expect(await hardhatDeSciPrint.deSciFileCIDs(1)).to.equal(paper2.paperCID);

            printInfo = await hardhatDeSciPrint.deSciPrints(paper2.paperCID);
            expect(printInfo.submitAddress).to.eq(address2.address);
            expect(printInfo.keyInfo).to.eq(paper2.keyInfo);
            expect(printInfo.submitTime).to.eq(blockTime);
            expect(printInfo.reviewerStatus).to.eq(0);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper2.paperCID);
            expect(processInfo.donate).to.eq(paper2.amount);
            expect(processInfo.processStatus).to.eq(0);
        });

        it("Get all prints in process by editor", async function () {
            const { hardhatDeSciPrint, editor1, paper1, paper2 } = await loadFixture(
                submitPrintsFixture
            );

            paperCIDs = await hardhatDeSciPrint.connect(editor1).editorPrintsPool();
            expect(paperCIDs).to.eql([paper1.paperCID, paper2.paperCID]);

        });

        it("assign the reviewers", async function () {
            const { hardhatDeSciPrint, reviewer1, reviewer2 } = await loadFixture(
                deployDeSciPrintFixture
            );

        });

    });

})

