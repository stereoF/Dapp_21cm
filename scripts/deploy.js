const path = require("path");

async function main() {

    // This is just a convenience check
    if (network.name === "hardhat") {
      console.warn(
        "You are trying to deploy a contract to the Hardhat Network, which" +
          "gets automatically created and destroyed every time. Use the Hardhat" +
          " option '--network localhost'"
      );
    }

      // ethers is available in the global scope
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    // const PrePrintTrack = await ethers.getContractFactory("PrePrintTrack");
    // const prePrintTrack = await PrePrintTrack.deploy();
    // await prePrintTrack.deployed();
    // console.log("PrePrintTrack address:", prePrintTrack.address);

    // We also save the contract's artifacts and address in the frontend directory
    // savePrePrintFrontendFiles(prePrintTrack);

    contracts = []
    // deSciPrintNames = ["Future", "Industrial Data Science", "PKU Space Science Review", "Complex system", "Decentralization"];
    deSciPrintNames = ["Physical Chemistry"];
    for (let i = 0; i < deSciPrintNames.length; i++) {
      const DeSciPrint = await ethers.getContractFactory("DeSciPrint");
      const deSciPrint = await DeSciPrint.deploy(deSciPrintNames[i]);
      await deSciPrint.deployed();
      contracts.push({"name": deSciPrintNames[i], "contract": deSciPrint});
      console.log("DeSciPrint name:", deSciPrintNames[i]);
      console.log("DeSciPrint address:", deSciPrint.address);
    };

    saveDeSciFrontendFiles(contracts);

  }

function savePrePrintFrontendFiles(prePrintTrack) {
  const fs = require("fs");
  // const contractsDir = path.join(__dirname, "..", "frontend", "src", "contracts");
  const contractsDir = path.join(__dirname, "..", "outputs", "contracts", "preprint");

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    path.join(contractsDir, "contract-address.json"),
    // JSON.stringify({ PrePrintTrack: prePrintTrack.address }, undefined, 2)
    JSON.stringify([{ "name": "PrePrintTrack", "address": prePrintTrack.address, "blockNumber": prePrintTrack.deployTransaction.blockNumber }], undefined, 2)
  );

  const PrePrintTrackArtifact = artifacts.readArtifactSync("PrePrintTrack");

  fs.writeFileSync(
    path.join(contractsDir, "PrePrintTrack.json"),
    JSON.stringify(PrePrintTrackArtifact, null, 2)
  );
}

function saveDeSciFrontendFiles(contracts) {
  const fs = require("fs");
  // const contractsDir = path.join(__dirname, "..", "frontend", "src", "contracts");
  const contractsDir = path.join(__dirname, "..", "outputs", "contracts", "desci");

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  contractAddresses = contracts.map((contract) => {
    return {"name": contract.name, "address": contract.contract.address, "blockNumber": contract.contract.deployTransaction.blockNumber}
  });

  fs.writeFileSync(
    path.join(contractsDir, "contract-address.json"),
    JSON.stringify(contractAddresses, undefined, 2)
  );

  const PrePrintTrackArtifact = artifacts.readArtifactSync("DeSciPrint");

  fs.writeFileSync(
    path.join(contractsDir, "DeSciPrint.json"),
    JSON.stringify(PrePrintTrackArtifact, null, 2)
  );
}
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });