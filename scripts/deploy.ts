import { ethers } from "hardhat";

async function main() {
  // const currentTimestampInSeconds = Math.round(Date.now() / 1000);

  const ZKDocsCore = await ethers.getContractFactory("ZKDocsCore");
  const deployPromisefully = await ZKDocsCore.deploy();

  await deployPromisefully.deployed();

  console.log(`Deployed to ${deployPromisefully.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
