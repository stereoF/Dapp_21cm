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
    it("Should emit events when deploy", async function () {
      const DeSciRoleModel = await ethers.getContractFactory("DeSciRoleModel");
      const hardhatDeSciRoleModel = await DeSciRoleModel.deploy();
      const receipt = await hardhatDeSciRoleModel.deployTransaction.wait();

      expect(receipt.events[0].event).to.equal("OwnershipTransferred");
      expect(receipt.events[0].args.previousOwner).to.equal(ethers.constants.AddressZero);
      expect(receipt.events[0].args.newOwner).to.equal(await hardhatDeSciRoleModel.owner());

    });

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

    it("should emit event when push editors", async function () {
      const { hardhatDeSciRoleModel, editor1, editor2 } = await loadFixture(
        deployDeSciRoleModelFixture
      );

      const blockTime = Date.now() + 5;
      await time.setNextBlockTimestamp(blockTime);

      expect(await hardhatDeSciRoleModel.pushEditors[editor1.address, editor2.address])
        .to.emit(hardhatDeSciRoleModel, "ChangeEditors")
        .withArgs(blockTime, 0, [], [editor1.address, editor2.address])

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

    it("should emit event when remove editors", async function () {
      const { hardhatDeSciRoleModel, editor1, editor2, address2 } = await loadFixture(
        deployDeSciRoleModelFixture
      );

      await hardhatDeSciRoleModel.pushEditors([editor1.address, editor2.address, address2.address]);

      const blockTime = Date.now() + 5;
      await time.setNextBlockTimestamp(blockTime);

      expect(await hardhatDeSciRoleModel.removeEditor([editor1.address, editor2.address]))
        .to.emit(hardhatDeSciRoleModel, "ChangeEditors")
        .withArgs(blockTime, 1, [editor1.address, editor2.address, address2.address], [editor1.address, editor2.address])

    });

    it("should fail if push duplicated editors", async function() {
      const { hardhatDeSciRoleModel, editor1, editor2 } = await loadFixture(
        deployDeSciRoleModelFixture
      );


      await expect(
        hardhatDeSciRoleModel.pushEditors([editor1.address, editor2.address, editor2.address])
      ).to.be.revertedWith("Duplicate editor");

      await hardhatDeSciRoleModel.pushEditors([editor1.address, editor2.address]);
      await expect(
        hardhatDeSciRoleModel.pushEditors([editor2.address])
      ).to.be.revertedWith("Duplicate editor");


    });

    it("add, remove, add editors", async function () {
      const { hardhatDeSciRoleModel, editor1, editor2, address2 } = await loadFixture(
        deployDeSciRoleModelFixture
      );

      await hardhatDeSciRoleModel.pushEditors([editor1.address, editor2.address, address2.address]);
      await hardhatDeSciRoleModel.removeEditor([editor1.address, editor2.address, address2.address]);
      await hardhatDeSciRoleModel.pushEditors([editor1.address, editor2.address, address2.address]);

    });

  });

});