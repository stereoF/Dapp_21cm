const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");
const { BigNumber } = require('ethers');


describe("DeSciPrint contract", function () {
    async function deployDeSciPrintFixture() {
        const [owner, address1, address2, editor1, editor2, reviewer1, reviewer2, reviewer3] = await ethers.getSigners();
        const DeSciPrint = await ethers.getContractFactory("DeSciPrint");
        const hardhatDeSciPrint = await DeSciPrint.deploy();
    
        return { hardhatDeSciPrint, owner, address1, address2, editor1, editor2, reviewer1, reviewer2, reviewer3 };
    };

    async function submitPrintsFixture() {

        const { hardhatDeSciPrint, owner, address1, address2, editor1, editor2, reviewer1, reviewer2, reviewer3 } = await loadFixture(
            deployDeSciPrintFixture
        );

        const minGasCost = await hardhatDeSciPrint.gasFee(0);
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
            reviewer1, reviewer2, reviewer3, paper1, paper2, minGasCost, blockTime };
    };

    async function assignReviewersFixture() {
        const { hardhatDeSciPrint, paper1, paper2, editor1, editor2, reviewer1, reviewer2, reviewer3 } = await loadFixture(
            submitPrintsFixture
        );

        // await hardhatDeSciPrint.connect(owner).pushReviewers([reviewer1.address, reviewer2.address, reviewer3.address]);

        await hardhatDeSciPrint.connect(editor1).reviewerAssign(paper1.paperCID, 
            [reviewer1.address, reviewer2.address, reviewer3.address]);

        await hardhatDeSciPrint.connect(editor2).reviewerAssign(paper2.paperCID, 
            [reviewer1.address, reviewer2.address]);

        return { hardhatDeSciPrint, editor1, editor2, reviewer1, reviewer2, reviewer3, paper1, paper2 };
    };

    describe("Management", function() {
        it("Set minGasCost", async function () {
            const { hardhatDeSciPrint } = await loadFixture(
                deployDeSciPrintFixture
            );

            const minGasCost = ethers.utils.parseEther('0.2', 'ether');
            await hardhatDeSciPrint.setGasFee(minGasCost, 0);
            
            expect(await hardhatDeSciPrint.gasFee(0)).to.equal(ethers.utils.parseEther('0.2', 'ether'));

        });

        it("change editor", async function () {
            const { hardhatDeSciPrint, owner, editor1, editor2, reviewer1, paper1 } = await loadFixture(
                submitPrintsFixture
            );

            await hardhatDeSciPrint.connect(editor1).reviewerAssign(paper1.paperCID, 
                [reviewer1.address]);
            processInfo = await hardhatDeSciPrint.deSciProcess(paper1.paperCID);
            expect(processInfo.editor).to.eq(editor1.address);

            await hardhatDeSciPrint.connect(owner).changeEditor(paper1.paperCID, editor2.address);
            processInfo = await hardhatDeSciPrint.deSciProcess(paper1.paperCID);
            expect(processInfo.editor).to.eq(editor2.address);
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
            // expect(printInfo.reviewerStatus).to.eq(0);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper2.paperCID);
            expect(processInfo.donate).to.eq(paper2.amount);
            expect(processInfo.processStatus).to.eq(0);
        });

        it("Get all prints in process by editor", async function () {
            const { hardhatDeSciPrint, editor1, paper1, paper2 } = await loadFixture(
                submitPrintsFixture
            );

            paperCIDs = await hardhatDeSciPrint.connect(editor1).printsPool(0);
            expect(paperCIDs).to.eql([paper1.paperCID, paper2.paperCID]);

        });

        it("Editor reject the paper", async function () {
            const { hardhatDeSciPrint, editor1 } = await loadFixture(
                submitPrintsFixture
            );

            let [paperCID1, paperCID2] = await hardhatDeSciPrint.connect(editor1).printsPool(0);
            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            const blockTime = Date.now() + 15;
            await time.setNextBlockTimestamp(blockTime);
            await hardhatDeSciPrint.connect(editor1).editorReject(paperCID1, comment)

            pendingCIDs = await hardhatDeSciPrint.connect(editor1).printsPool(0);
            expect(pendingCIDs).to.eql([paperCID2]);

            rejectedCIDs = await hardhatDeSciPrint.connect(editor1).printsPool(2);
            expect(rejectedCIDs).to.eql([paperCID1]);

            processInfo = await hardhatDeSciPrint.deSciProcess(paperCID1);
            expect(processInfo.editor).to.eq(editor1.address);
            expect(processInfo.processStatus).to.eq(2);

            reviewInfo = await hardhatDeSciPrint.deSciReviews(paperCID1, editor1.address);
            expect(reviewInfo.comment).to.eq(comment);
            expect(reviewInfo.commentTime).to.eq(blockTime);
            expect(reviewInfo.reviewerStatus).to.eq(2)

        });

        it("Need append reviewer if less than 2 reviewers", async function () {
            const { hardhatDeSciPrint, paper1, editor1, reviewer1 } = await loadFixture(
                submitPrintsFixture
            );

            await hardhatDeSciPrint.connect(editor1).reviewerAssign(paper1.paperCID, 
                [reviewer1.address]);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper1.paperCID);
            expect(processInfo.processStatus).to.eq(4);
        });

        it("Fail if assign more than 3 reviewers", async function () {
            const { hardhatDeSciPrint, paper1, editor1, editor2, reviewer1, reviewer2, reviewer3 } = await loadFixture(
                submitPrintsFixture
            );
            
            await expect(hardhatDeSciPrint.connect(editor1).reviewerAssign(paper1.paperCID, 
                [reviewer1.address, reviewer2.address, reviewer3.address, editor2.address]))
                .to.be.revertedWith("No more than 3 reviewers");
        });

        it("The pending list and in-review list after reviewers assignment", async function () {
            const { hardhatDeSciPrint, editor1, paper1, paper2 } = await loadFixture(
                assignReviewersFixture
            );

            paperCIDs = await hardhatDeSciPrint.connect(editor1).printsPool(0);
            expect(paperCIDs).to.eql([]);

            paperCIDs = await hardhatDeSciPrint.connect(editor1).printsPool(1);
            expect(paperCIDs).to.eql([paper1.paperCID, paper2.paperCID]);

        });

        it("The processInfo after reviewers assignment", async function () {
            const { hardhatDeSciPrint, paper1, editor1, reviewer1, reviewer2, reviewer3 } = await loadFixture(
                assignReviewersFixture
            );

            processInfo = await hardhatDeSciPrint.deSciProcess(paper1.paperCID);
            reviewers = await hardhatDeSciPrint.getReviewers(paper1.paperCID);
            expect(reviewers).to.eql([reviewer1.address, reviewer2.address, reviewer3.address]);
            expect(processInfo.donate).to.eq(paper1.amount);
            expect(processInfo.editor).to.eq(editor1.address);
            expect(processInfo.processStatus).to.eq(1);
        });

        it("Reviewer submit comment", async function () {
            const { hardhatDeSciPrint, reviewer1, paper1 } = await loadFixture(
                assignReviewersFixture
            );

            const blockTime = Date.now() + 15;
            await time.setNextBlockTimestamp(blockTime);

            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper1.paperCID, comment, 1);

            reviewInfo = await hardhatDeSciPrint.deSciReviews(paper1.paperCID, reviewer1.address);
            expect(reviewInfo.comment).to.eq(comment);
            expect(reviewInfo.commentTime).to.eq(blockTime);
            expect(reviewInfo.reviewerStatus).to.eq(1);
        });

        it("Remove 2 reviewers then need append reviewer", async function () {
            const { hardhatDeSciPrint, editor1, reviewer1, reviewer2, reviewer3, paper1 } = await loadFixture(
                assignReviewersFixture
            );

            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper1.paperCID, comment, 3);
            await hardhatDeSciPrint.connect(editor1).removeReviewer(paper1.paperCID, [reviewer2.address, reviewer3.address]);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper1.paperCID);
            expect(processInfo.processStatus).to.eq(4);
        });

        it("Fail if remove a reviewer with action", async function () {
            const { hardhatDeSciPrint, editor1, reviewer1, reviewer2, reviewer3, paper1 } = await loadFixture(
                assignReviewersFixture
            );

            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper1.paperCID, comment, 3);
            await expect(
                hardhatDeSciPrint.connect(editor1).removeReviewer(paper1.paperCID, [reviewer1.address, reviewer3.address])
              ).to.be.revertedWith("Can only remove no action reviewer");

        });

        it(">= 2 pass then publish", async function () {
            const { hardhatDeSciPrint, paper1, paper2, reviewer1, reviewer2 } = await loadFixture(
                assignReviewersFixture
            );

            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper1.paperCID, comment, 3);

            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs5';
            await hardhatDeSciPrint.connect(reviewer2).reviewPrint(paper1.paperCID, comment, 3);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper1.paperCID);
            expect(processInfo.processStatus).to.eq(7);

            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs7';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper2.paperCID, comment, 3);
            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs6';
            await hardhatDeSciPrint.connect(reviewer2).reviewPrint(paper2.paperCID, comment, 3);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper2.paperCID);
            expect(processInfo.processStatus).to.eq(7);
        });

        it(">= 2 reject then reject", async function () {
            const { hardhatDeSciPrint, paper1, reviewer1, reviewer2, reviewer3 } = await loadFixture(
                assignReviewersFixture
            );

            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper1.paperCID, comment, 2);

            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs5';
            await hardhatDeSciPrint.connect(reviewer2).reviewPrint(paper1.paperCID, comment, 2);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper1.paperCID);
            expect(processInfo.processStatus).to.eq(3);
        });

        it("Need append reviewer if 1 reject among 2 reviewers", async function () {
            const { hardhatDeSciPrint, paper2, reviewer1 } = await loadFixture(
                assignReviewersFixture
            );

            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper2.paperCID, comment, 2);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper2.paperCID);
            expect(processInfo.processStatus).to.eq(4);
        });

        it("Need revise if 1 revise, 1 pass and 1 reject", async function () {
            const { hardhatDeSciPrint, paper1, reviewer1, reviewer2, reviewer3 } = await loadFixture(
                assignReviewersFixture
            );

            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper1.paperCID, comment, 2);
            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer2).reviewPrint(paper1.paperCID, comment, 1);
            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer3).reviewPrint(paper1.paperCID, comment, 3);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper1.paperCID);
            expect(processInfo.processStatus).to.eq(5);

        });

        it("Need revise if 2 revise", async function () {
            const { hardhatDeSciPrint, paper2, reviewer1, reviewer2 } = await loadFixture(
                assignReviewersFixture
            );

            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper2.paperCID, comment, 1);
            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer2).reviewPrint(paper2.paperCID, comment, 1);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper2.paperCID);
            expect(processInfo.processStatus).to.eq(5);

        });

        it("Need revise if 2 revise and 1 reject", async function () {
            const { hardhatDeSciPrint, paper1, reviewer1, reviewer2, reviewer3 } = await loadFixture(
                assignReviewersFixture
            );

            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper1.paperCID, comment, 1);
            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer2).reviewPrint(paper1.paperCID, comment, 1);
            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer3).reviewPrint(paper1.paperCID, comment, 2);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper1.paperCID);
            expect(processInfo.processStatus).to.eq(5);

        });

        it("Need revise if 2 revise and 1 pass", async function () {
            const { hardhatDeSciPrint, paper1, reviewer1, reviewer2, reviewer3 } = await loadFixture(
                assignReviewersFixture
            );

            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper1.paperCID, comment, 1);
            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer2).reviewPrint(paper1.paperCID, comment, 1);
            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer3).reviewPrint(paper1.paperCID, comment, 3);

            processInfo = await hardhatDeSciPrint.deSciProcess(paper1.paperCID);
            expect(processInfo.processStatus).to.eq(5);

        });

    });

    describe.only("economy system", function() {
        async function allocateBalanceFixture() {
            const { hardhatDeSciPrint, address1, editor1, reviewer1, reviewer2 } = await loadFixture(
                deployDeSciPrintFixture
            );

            const minGasCost = await hardhatDeSciPrint.gasFee(0);
            const editorGas = await hardhatDeSciPrint.gasFee(1);
            const reviewerGas = await hardhatDeSciPrint.gasFee(2);
            const bonusWeight = await hardhatDeSciPrint.bonusWeight();

            let totalBonusWeight = BigNumber.from("0");
            for(let i = 0;i<bonusWeight.length;i++){
                totalBonusWeight = totalBonusWeight.add(bonusWeight[i]);
            }

            await hardhatDeSciPrint.pushEditors([editor1.address]);
    
            const paper1 = {
                paperCID: "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyHo",
                keyInfo: 'paper 1',
                amount: ethers.utils.parseEther('0.5', 'ether')
            };

            totalAmount = paper1.amount.add(minGasCost);
            await hardhatDeSciPrint.connect(address1).submitForReview(paper1.paperCID, paper1.keyInfo, paper1.amount, 
                { value: totalAmount });

            await hardhatDeSciPrint.connect(editor1).reviewerAssign(paper1.paperCID, 
                [reviewer1.address, reviewer2.address]);

            const editorBonus = paper1.amount.div(totalBonusWeight).mul(bonusWeight[3]);
            let editorBalance = editorGas.add(editorBonus);

            let comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs4';
            await hardhatDeSciPrint.connect(reviewer1).reviewPrint(paper1.paperCID, comment, 3);

            comment = 'QmakBV63npN4DLpYheBq9jp79yLqsGi3caSUtJ8GCUQTs5';
            await hardhatDeSciPrint.connect(reviewer2).reviewPrint(paper1.paperCID, comment, 3);

            const reviewerBonus = paper1.amount.div(totalBonusWeight).mul(bonusWeight[0]);
            const reviewerBalance = reviewerGas.add(reviewerBonus);

            const publishBonus = paper1.amount.div(totalBonusWeight).mul(bonusWeight[7]);
            editorBalance = editorBalance.add(publishBonus)

            return { hardhatDeSciPrint, minGasCost, editorGas, reviewerGas, paper1, totalAmount, editor1, 
                reviewer1, reviewer2, editorBalance, reviewerBalance};

        };

        it("the balance should be equal to the amount transfer to the contract", async function () {
            const { hardhatDeSciPrint, address1 } = await loadFixture(
                deployDeSciPrintFixture
            );

            tx = {
                to: hardhatDeSciPrint.address,
                value: ethers.utils.parseEther('10', 'ether')
            };
            const transaction = await address1.sendTransaction(tx);
        
            expect(await hardhatDeSciPrint.getBalance()).to.equal(ethers.utils.parseEther('10', 'ether'));

        });


        it("The balance amount", async function () {
            const { hardhatDeSciPrint, minGasCost, editorGas, reviewerGas, paper1, totalAmount, editor1, 
                reviewer1, reviewer2, editorBalance, reviewerBalance} = await loadFixture(
                allocateBalanceFixture
            );

            expect(await hardhatDeSciPrint.getBalance()).to.eq(totalAmount);
            expect(await hardhatDeSciPrint.tokenBalance(editor1.address)).to.eq(editorBalance);
            expect(await hardhatDeSciPrint.tokenBalance(reviewer1.address)).to.eq(reviewerBalance);
            expect(await hardhatDeSciPrint.tokenBalance(reviewer2.address)).to.eq(reviewerBalance);
        });

    })

})

