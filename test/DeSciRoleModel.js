const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");

describe("DeSciRoleModel contract", function () {

  async function deployDeSciRoleModelFixture() {
    const [owner, address2] = await ethers.getSigners();
    const DeSciRoleModel = await ethers.getContractFactory("DeSciRoleModel");
    const hardhatDeSciRoleModel = await DeSciRoleModel.deploy();

    return { hardhatDeSciRoleModel, owner, address2 }
  }

  describe("Deployment", function() {
    it("Should set the right owner", async function () {
      const { hardhatDeSciRoleModel, owner } = await loadFixture(
        deployDeSciRoleModelFixture
      );

      expect(owner.address).to.equal(await hardhatDeSciRoleModel.owner());
    });
  });

});