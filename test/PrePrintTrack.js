const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");

describe("PrePrintTrack contract", function () {

  async function deployPrePrintTrackFixture() {
    const [owner, address2] = await ethers.getSigners();
    const PrePrintTrack = await ethers.getContractFactory("PrePrintTrack");
    const hardhatPrePrintTrack = await PrePrintTrack.deploy();

    return { hardhatPrePrintTrack, owner, address2 }
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { hardhatPrePrintTrack, owner } = await loadFixture(
        deployPrePrintTrackFixture
      );

      expect(owner.address).to.equal(await hardhatPrePrintTrack.owner());
    });
  });

  describe("Management", function () {
    it("transfer the ownership", async function () {
      const { hardhatPrePrintTrack, owner, address2 } = await loadFixture(
        deployPrePrintTrackFixture
      );

      await hardhatPrePrintTrack.transferOwnership(address2.address);
      expect(address2.address).to.equal(await hardhatPrePrintTrack.owner());

    });
  });

  describe("Transaction", function () {
    it("should submit the paper's CID", async function () {
      const { hardhatPrePrintTrack, owner } = await loadFixture(
        deployPrePrintTrackFixture
      );

      const paperCID = "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyHo";
      const keyInfo = 'test key information'

      const blockTime = Date.now() + 2;
      await time.setNextBlockTimestamp(blockTime);

      await hardhatPrePrintTrack.submit(paperCID, keyInfo, 'test description');

      // expect(await hardhatPrePrintTrack.prePrintCIDs(0,0)).to.equal(paperCID);
      let prePrintCnt = await hardhatPrePrintTrack.prePrintCnt();
      expect(prePrintCnt).to.equal(1);
      expect(await hardhatPrePrintTrack.prePrintCIDMap(prePrintCnt - 1)).to.equal(paperCID);

      let prePrintInfo = await hardhatPrePrintTrack.prePrints(paperCID);
      expect(prePrintInfo.submitAddress).to.equal(owner.address);
      expect(prePrintInfo.keyInfo).to.equal(keyInfo);
      expect(prePrintInfo.submitTime).to.equal(blockTime);

    });

    it("should get all CIDs by index range", async function () {
      const { hardhatPrePrintTrack, owner } = await loadFixture(
        deployPrePrintTrackFixture
      );

      const paperCIDs = [
        "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyH1",
        "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyH2",
        "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyH3"
      ]
      const keyInfo = 'test key information'

      await hardhatPrePrintTrack.submit(paperCIDs[0], keyInfo, 'test description');
      await hardhatPrePrintTrack.submit(paperCIDs[1], keyInfo, 'test description');
      await hardhatPrePrintTrack.submit(paperCIDs[2], keyInfo, 'test description');

      let prePrintCnt = await hardhatPrePrintTrack.prePrintCnt();
      expect(prePrintCnt).to.equal(3);
      let prePrintCIDs = await hardhatPrePrintTrack.prePrintCIDs(0, prePrintCnt - 1);
      expect(prePrintCIDs).to.eql(paperCIDs);

    });

    it("should emit Submit events", async function () {
      const { hardhatPrePrintTrack, owner } = await loadFixture(
        deployPrePrintTrackFixture
      );

      const paperCID = "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyHo";
      const keyInfo = 'test key information'

      const blockTime = Date.now() + 2;
      await time.setNextBlockTimestamp(blockTime);

      expect(await hardhatPrePrintTrack.submit(paperCID, keyInfo, 'test description'))
        .to.emit(hardhatPrePrintTrack, "Submit")
        .withArgs(paperCID, keyInfo, owner.address, blockTime, 'test description');
    });

    it("should fail if two same file submitted", async function () {
      const { hardhatPrePrintTrack } = await loadFixture(
        deployPrePrintTrackFixture
      );

      const paperCID = "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyHo";
      const keyInfo = 'test key information'

      await hardhatPrePrintTrack.submit(paperCID, keyInfo, '1st submit');

      await expect(
        hardhatPrePrintTrack.submit(paperCID, keyInfo, '2nd submit')
      ).to.be.revertedWith("The cid of file has existed!");

    });

    it("getAuthorPapers should return right results", async function () {
      const { hardhatPrePrintTrack, owner, address2 } = await loadFixture(
        deployPrePrintTrackFixture
      );

      const paper1 = {
        paperCID: "paper1CID",
        keyInfo: 'paper1 key info',
        description: 'paper1 description',
      };

      const paper2 = {
        paperCID: "paper2CID",
        keyInfo: 'paper2 key info',
        description: 'paper2 description',
      };

      const paper3 = {
        paperCID: "paper3CID",
        keyInfo: 'paper3 key info',
        description: 'paper3 description',
      };

      await hardhatPrePrintTrack.connect(address2).submit(paper1.paperCID, paper1.keyInfo, paper1.description);
      await hardhatPrePrintTrack.connect(address2).submit(paper2.paperCID, paper2.keyInfo, paper2.description);
      await hardhatPrePrintTrack.connect(owner).submit(paper3.paperCID, paper3.keyInfo, paper3.description);

      const printCnt = await hardhatPrePrintTrack.prePrintCnt();

      expect(await hardhatPrePrintTrack.getAuthorPapers(address2.address, 0, printCnt - 1)).to.deep.eq([paper1.paperCID, paper2.paperCID]);
      expect(await hardhatPrePrintTrack.getAuthorPapers(owner.address, 0, printCnt - 1)).to.deep.eq([paper3.paperCID]);

    });

    it("the balance should be equal to the amount transfer to the contract", async function () {
      const { hardhatPrePrintTrack, address2 } = await loadFixture(
        deployPrePrintTrackFixture
      );

      tx = {
        to: hardhatPrePrintTrack.address,
        value: ethers.utils.parseEther('10', 'ether')
      };
      const transaction = await address2.sendTransaction(tx);

      expect(await hardhatPrePrintTrack.getBalance()).to.equal(ethers.utils.parseEther('10', 'ether'));

    });

    it("the balance of the contract and owner after withdraw", async function () {
      const { hardhatPrePrintTrack, owner, address2 } = await loadFixture(
        deployPrePrintTrackFixture
      );

      tx = {
        to: hardhatPrePrintTrack.address,
        value: ethers.utils.parseEther('10', 'ether')
      };
      const transaction = await address2.sendTransaction(tx);

      initialBalance = await owner.getBalance()
      // let's do a withdrawal
      const tx2 = await hardhatPrePrintTrack.connect(owner).withdraw();
      // Let's calculate the gas spent
      const receipt = await tx2.wait()
      const gasSpent = receipt.gasUsed.mul(receipt.effectiveGasPrice)

      expect(await owner.getBalance()).to.eq(ethers.utils.parseEther('10', 'ether').add(initialBalance).sub(gasSpent))

    });

  });
});