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

  describe("Deployment", function() {
    it("Should set the right owner", async function () {
      const { hardhatPrePrintTrack, owner } = await loadFixture(
        deployPrePrintTrackFixture
      );

      expect(owner.address).to.equal(await hardhatPrePrintTrack.owner());
    });
  });

  describe("Transaction", function(){
    it("should submit the paper's CID", async function(){
      const { hardhatPrePrintTrack, owner } = await loadFixture(
        deployPrePrintTrackFixture
      );
      
      const paperCID = "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyHo";
      const keyInfo = 'test key information'
      await hardhatPrePrintTrack.submit(paperCID, keyInfo, 'test description');

      expect(await hardhatPrePrintTrack.prePrintCIDs(0)).to.equal(paperCID);

      let prePrintInfo = await hardhatPrePrintTrack.prePrints(paperCID);
      expect(prePrintInfo.submitAddress).to.equal(owner.address);
      expect(prePrintInfo.keyInfo).to.equal(keyInfo);

    });

    it("should emit Submit events", async function() {
      const { hardhatPrePrintTrack, owner } = await loadFixture(
        deployPrePrintTrackFixture
      );

      const paperCID = "QmT1n5DZWHurMHC5DuMi7DZ7NaYkZQmi6iq9GszVdwvyHo";
      const keyInfo = 'test key information'

      const blockTime = Date.now() + 15;
      await time.setNextBlockTimestamp(blockTime);

      await expect(await hardhatPrePrintTrack.submit(paperCID, keyInfo, 'test description'))
      .to.emit(hardhatPrePrintTrack, "Submit")
      .withArgs(paperCID, keyInfo, owner.address, blockTime, 'test description');
    });

    it("should fail if two same file submitted", async function() {
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

    it("the balance should be equal to the amount transfer to the contract", async function() {
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

  });
});