import { ethers } from "hardhat";

async function main() {
  const ZKDocsScheduler = await ethers.getContractFactory("ZKDocsScheduler");
  const ZKDocsCore = await ethers.getContractFactory("ZKDocsCore");
  const schedulerDeployed = await ZKDocsScheduler.deploy();
  await schedulerDeployed.deployed();

  const addressOfScheduler = schedulerDeployed.address;
  const deployPromisefully = await ZKDocsCore.deploy(addressOfScheduler);
  await deployPromisefully.deployed();

  console.log(`Core contract deployed to ${deployPromisefully.address} and scheduler to ${addressOfScheduler}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
