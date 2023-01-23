const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");

describe("DeSciRoleModel contract", function () {

  async function deployDeSciRoleModelFixture() {
    const [owner, address2, admin, editor, reviewer] = await ethers.getSigners();
    const DeSciRoleModel = await ethers.getContractFactory("DeSciRoleModel");
    const hardhatDeSciRoleModel = await DeSciRoleModel.deploy();

    return { hardhatDeSciRoleModel, owner, address2, admin, editor, reviewer }
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

    it("assign the admin", async function () {
        const { hardhatDeSciRoleModel, admin } = await loadFixture(
          deployDeSciRoleModelFixture
        );
  
        await hardhatDeSciRoleModel.assignAdministrator(admin.address);
        expect(admin.address).to.equal((await hardhatDeSciRoleModel.admins())[0]);
        expect(await hardhatDeSciRoleModel.connect(admin).isAdmin()).to.equal(true);
  
      });
  });

});