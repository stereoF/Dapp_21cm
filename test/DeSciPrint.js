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
        it("Submit", async function () {
            const { hardhatDeSciPrint, address2 } = await loadFixture(
            deployDeSciPrintFixture
            );

            const paperCID = "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyHo";
            const keyInfo = 'test key information';
            const amount = ethers.utils.parseEther('1.5', 'ether');

            const minGasCost = await hardhatDeSciPrint.minGasCost();

            const blockTime = Date.now() + 15;
            await time.setNextBlockTimestamp(blockTime);
            
            await hardhatDeSciPrint.connect(address2).submitForReview(paperCID, keyInfo, amount, { value: amount.add(minGasCost) });
            expect(await hardhatDeSciPrint.deSciFileCIDs(0)).to.equal(paperCID);
            expect(await hardhatDeSciPrint.getBalance()).to.equal(amount.add(minGasCost));

            printInfo = await hardhatDeSciPrint.deSciPrints(paperCID);
            expect(printInfo.submitAddress).to.eq(address2.address);
            expect(printInfo.keyInfo).to.eq(keyInfo);
            expect(printInfo.submitTime).to.eq(blockTime);
            expect(printInfo.reviewerStatus).to.eq(0);

            processInfo = await hardhatDeSciPrint.deSciProcess(paperCID);
            expect(processInfo.donate).to.eq(amount);
            expect(processInfo.processStatus).to.eq(0);
        });

        it("Get all prints in process by editor", async function () {
            const { hardhatDeSciPrint, address1, address2, editor1} = await loadFixture(
                deployDeSciPrintFixture
            );
            const minGasCost = await hardhatDeSciPrint.minGasCost();
            await hardhatDeSciPrint.pushEditors([editor1.address]);

            let paperCID1 = "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyHo";
            let keyInfo = 'paper 1';
            let amount = ethers.utils.parseEther('1.5', 'ether');
            await hardhatDeSciPrint.connect(address1).submitForReview(paperCID1, keyInfo, amount, { value: amount.add(minGasCost) });

            let paperCID2 = "QmakBV63npN4DLpYheAq9jpn9yLqsGi3caSUtJ8GCUQ27H";
            keyInfo = 'paper 2';
            amount = ethers.utils.parseEther('1.7', 'ether');
            await hardhatDeSciPrint.connect(address2).submitForReview(paperCID2, keyInfo, amount, { value: amount.add(minGasCost) });

            paperCIDs = await hardhatDeSciPrint.connect(editor1).editorPrintsPool();
            expect(paperCIDs).to.eql([paperCID1, paperCID2]);

        });

        it("assign the reviewers", async function () {
            const { hardhatDeSciPrint, reviewer1, reviewer2 } = await loadFixture(
                deployDeSciPrintFixture
            );

        });

    });

})

