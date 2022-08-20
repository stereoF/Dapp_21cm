async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PrePrintTrack = await ethers.getContractFactory("PrePrintTrack");
    const prePrintTrack = await PrePrintTrack.deploy();
  
    console.log("PrePrintTrack address:", prePrintTrack.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });