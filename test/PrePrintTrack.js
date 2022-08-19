const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("PrePrintTrack contract", function () {

  async function deployPrePrintTrackFixture() {
    const [owner] = await ethers.getSigners();
    const PrePrintTrack = await ethers.getContractFactory("PrePrintTrack");
    const hardhatPrePrintTrack = await PrePrintTrack.deploy();

    return { hardhatPrePrintTrack, owner }
  }

  describe("Deployment", function() {
    it("Should set the right owner", async function () {
      const { hardhatPrePrintTrack, owner } = await loadFixture(
        deployPrePrintTrackFixture
      );

      expect(owner.address).to.equal(hardhatPrePrintTrack.owner());
    });
  });

  describe("Transaction", function(){
    it("should submit the paper's CID", async function(){
      const { hardhatPrePrintTrack, owner } = await loadFixture(
        deployPrePrintTrackFixture
      );

      
    });
  });
});