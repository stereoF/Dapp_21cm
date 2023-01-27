const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");

describe("DeSciRoleModel contract", function () {

  async function deployDeSciRoleModelFixture() {
    const [owner, address2, editor1, editor2, reviewer1, reviewer2] = await ethers.getSigners();
    const DeSciRoleModel = await ethers.getContractFactory("DeSciRoleModel");
    const hardhatDeSciRoleModel = await DeSciRoleModel.deploy();

    return { hardhatDeSciRoleModel, owner, address2, editor1, editor2, reviewer1, reviewer2 }
  }

  describe("Deployment", function() {
    it("Should set the right owner", async function () {
      const { hardhatDeSciRoleModel, owner } = await loadFixture(
        deployDeSciRoleModelFixture
      );

      expect(owner.address).to.equal(await hardhatDeSciRoleModel.owner());
    });
  });

  describe("Management", function() {
    it("transfer the ownership", async function () {
      const { hardhatDeSciRoleModel, address2 } = await loadFixture(
        deployDeSciRoleModelFixture
      );

      await hardhatDeSciRoleModel.transferOwnership(address2.address);
      expect(address2.address).to.equal(await hardhatDeSciRoleModel.owner());

    });

    it("assign the editors", async function () {
        const { hardhatDeSciRoleModel, editor1, editor2 } = await loadFixture(
          deployDeSciRoleModelFixture
        );

        await hardhatDeSciRoleModel.pushEditors([editor1.address, editor2.address]);
        expect(editor1.address).to.equal((await hardhatDeSciRoleModel.editors())[0]);
        expect(editor2.address).to.equal((await hardhatDeSciRoleModel.editors())[1]);
        expect(await hardhatDeSciRoleModel.connect(editor1).isEditor()).to.equal(true);
        expect(await hardhatDeSciRoleModel.connect(editor2).isEditor()).to.equal(true);
      });

    it("remove editors", async function () {
        const { hardhatDeSciRoleModel, editor1, editor2, address2 } = await loadFixture(
          deployDeSciRoleModelFixture
        );

        await hardhatDeSciRoleModel.pushEditors([editor1.address, editor2.address, address2.address]);
        expect(await hardhatDeSciRoleModel.connect(editor1).isEditor()).to.equal(true);
        expect(await hardhatDeSciRoleModel.connect(editor2).isEditor()).to.equal(true);
        expect(await hardhatDeSciRoleModel.connect(address2).isEditor()).to.equal(true);

        await hardhatDeSciRoleModel.removeEditor([editor1.address, editor2.address]);
        expect(await hardhatDeSciRoleModel.connect(editor1).isEditor()).to.equal(false);
        expect(await hardhatDeSciRoleModel.connect(editor2).isEditor()).to.equal(false);
        expect(await hardhatDeSciRoleModel.connect(address2).isEditor()).to.equal(true);
    });

    // it("assign the reviewers", async function () {
    //   const { hardhatDeSciRoleModel, reviewer1, reviewer2 } = await loadFixture(
    //     deployDeSciRoleModelFixture
    //   );

    //   await hardhatDeSciRoleModel.pushReviewers([reviewer1.address, reviewer2.address]);
    //   expect(await hardhatDeSciRoleModel.connect(reviewer1).isReviewer()).to.equal(true);
    //   expect(await hardhatDeSciRoleModel.connect(reviewer2).isReviewer()).to.equal(true);
    // });

    // it("remove reviewers", async function () {
    //   const { hardhatDeSciRoleModel, reviewer1, reviewer2, address2 } = await loadFixture(
    //     deployDeSciRoleModelFixture
    //   );

    //   await hardhatDeSciRoleModel.pushReviewers([reviewer1.address, reviewer2.address, address2.address]);
    //   expect(await hardhatDeSciRoleModel.connect(reviewer1).isReviewer()).to.equal(true);
    //   expect(await hardhatDeSciRoleModel.connect(reviewer2).isReviewer()).to.equal(true);
    //   expect(await hardhatDeSciRoleModel.connect(address2).isReviewer()).to.equal(true);

    //   await hardhatDeSciRoleModel.removeReviewer([reviewer1.address, reviewer2.address]);
    //   expect(await hardhatDeSciRoleModel.connect(reviewer1).isReviewer()).to.equal(false);
    //   expect(await hardhatDeSciRoleModel.connect(reviewer2).isReviewer()).to.equal(false);
    //   expect(await hardhatDeSciRoleModel.connect(address2).isReviewer()).to.equal(true);
    // });

  });

});