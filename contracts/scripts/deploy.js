const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy VotingToken
  const VotingToken = await hre.ethers.getContractFactory("VotingToken");
  const votingToken = await VotingToken.deploy();
  await votingToken.deployed();
  console.log("VotingToken deployed to:", votingToken.address);

  // Deploy ElectionSystem
  const ElectionSystem = await hre.ethers.getContractFactory("ElectionSystem");
  const electionSystem = await ElectionSystem.deploy(votingToken.address);
  await electionSystem.deployed();
  console.log("ElectionSystem deployed to:", electionSystem.address);

  // Grant minter role to ElectionSystem
  const MINTER_ROLE = await votingToken.MINTER_ROLE();
  await votingToken.grantRole(MINTER_ROLE, electionSystem.address);
  console.log("Granted MINTER_ROLE to ElectionSystem");

  // Verify contracts
  if (hre.network.name !== "hardhat") {
    console.log("Waiting for block confirmations...");
    await votingToken.deployTransaction.wait(6);
    await electionSystem.deployTransaction.wait(6);

    console.log("Verifying contracts...");
    await hre.run("verify:verify", {
      address: votingToken.address,
      constructorArguments: [],
    });

    await hre.run("verify:verify", {
      address: electionSystem.address,
      constructorArguments: [votingToken.address],
    });
  }

  // Save contract addresses
  const fs = require("fs");
  const addresses = {
    votingToken: votingToken.address,
    electionSystem: electionSystem.address,
  };

  fs.writeFileSync(
    "deployed-addresses.json",
    JSON.stringify(addresses, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
