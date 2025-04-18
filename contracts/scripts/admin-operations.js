const hre = require("hardhat");

async function main() {
  const [admin] = await hre.ethers.getSigners();
  console.log("Performing admin operations with:", admin.address);

  // Load deployed addresses
  const addresses = require("../deployed-addresses.json");

  // Get contract instances
  const electionSystem = await hre.ethers.getContractAt(
    "ElectionSystem",
    addresses.electionSystem
  );
  const votingToken = await hre.ethers.getContractAt(
    "VotingToken",
    addresses.votingToken
  );

  // Example operations (uncomment and modify as needed)

  // 1. Add candidates
  console.log("Adding candidates...");
  await electionSystem.addCandidate("Candidate 1");
  await electionSystem.addCandidate("Candidate 2");
  await electionSystem.addCandidate("Candidate 3");
  console.log("Added candidates");

  // 2. Mint voting tokens to voters
  // const voters = [
  //   "0x...", // Add voter addresses
  //   "0x...",
  // ];
  // console.log("Minting voting tokens...");
  // for (const voter of voters) {
  //   await votingToken.mint(voter, 1);
  //   console.log(`Minted token to ${voter}`);
  // }

  // 3. Check current state
  console.log("\nCurrent State:");
  const candidateCount = await electionSystem.candidateCount();
  console.log(`Total candidates: ${candidateCount}`);

  for (let i = 1; i <= candidateCount; i++) {
    const candidate = await electionSystem.getCandidate(i);
    console.log(
      `Candidate ${i}: ${candidate.name}, Votes: ${candidate.voteCount}`
    );
  }

  // 4. End election (uncomment when ready)
  // console.log("\nEnding election...");
  // await electionSystem.endElection();
  // const winner = await electionSystem.getWinner();
  // console.log(`Winner: ${winner.name} with ${winner.voteCount} votes`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
