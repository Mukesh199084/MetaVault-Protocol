const { ethers } = require("hardhat");

async function main() {
  const MetaVaultProtocol = await ethers.getContractFactory("MetaVaultProtocol");
  const metaVaultProtocol = await MetaVaultProtocol.deploy();

  await metaVaultProtocol.deployed();

  console.log("MetaVaultProtocol contract deployed to:", metaVaultProtocol.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
