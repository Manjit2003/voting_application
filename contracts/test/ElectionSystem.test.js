const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ElectionSystem", function () {
  let electionSystem;
  let votingToken;
  let owner;
  let voter1;
  let voter2;
  let voter3;

  beforeEach(async function () {
    [owner, voter1, voter2, voter3] = await ethers.getSigners();

    // Deploy VotingToken
    const VotingToken = await ethers.getContractFactory("VotingToken");
    votingToken = await VotingToken.deploy();
    await votingToken.deployed();

    // Deploy ElectionSystem
    const ElectionSystem = await ethers.getContractFactory("ElectionSystem");
    electionSystem = await ElectionSystem.deploy(votingToken.address);
    await electionSystem.deployed();

    // Grant minter role to ElectionSystem
    const MINTER_ROLE = await votingToken.MINTER_ROLE();
    await votingToken.grantRole(MINTER_ROLE, electionSystem.address);
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await electionSystem.owner()).to.equal(owner.address);
    });

    it("Should have the right voting token", async function () {
      expect(await electionSystem.votingToken()).to.equal(votingToken.address);
    });
  });

  describe("Candidate Management", function () {
    it("Should allow owner to add candidates", async function () {
      await electionSystem.addCandidate("Candidate 1");
      const candidate = await electionSystem.getCandidate(1);
      expect(candidate.name).to.equal("Candidate 1");
      expect(candidate.voteCount).to.equal(0);
    });

    it("Should not allow non-owner to add candidates", async function () {
      await expect(
        electionSystem.connect(voter1).addCandidate("Candidate 1")
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Voting", function () {
    beforeEach(async function () {
      await electionSystem.addCandidate("Candidate 1");
      await electionSystem.addCandidate("Candidate 2");

      // Mint voting tokens
      await votingToken.mint(voter1.address, 1);
      await votingToken.mint(voter2.address, 1);
    });

    it("Should allow token holder to vote", async function () {
      await votingToken.connect(voter1).approve(electionSystem.address, 1);
      await electionSystem.connect(voter1).castVote(1);

      const candidate = await electionSystem.getCandidate(1);
      expect(candidate.voteCount).to.equal(1);
    });

    it("Should not allow voting without token", async function () {
      await expect(
        electionSystem.connect(voter3).castVote(1)
      ).to.be.revertedWith("No voting tokens");
    });

    it("Should not allow double voting", async function () {
      await votingToken.connect(voter1).approve(electionSystem.address, 1);
      await electionSystem.connect(voter1).castVote(1);

      await expect(
        electionSystem.connect(voter1).castVote(1)
      ).to.be.revertedWith("Already voted");
    });
  });

  describe("Election End", function () {
    beforeEach(async function () {
      await electionSystem.addCandidate("Candidate 1");
      await electionSystem.addCandidate("Candidate 2");

      await votingToken.mint(voter1.address, 1);
      await votingToken.mint(voter2.address, 1);

      await votingToken.connect(voter1).approve(electionSystem.address, 1);
      await votingToken.connect(voter2).approve(electionSystem.address, 1);

      await electionSystem.connect(voter1).castVote(1);
      await electionSystem.connect(voter2).castVote(1);
    });

    it("Should correctly determine the winner", async function () {
      await electionSystem.endElection();
      const winner = await electionSystem.getWinner();
      expect(winner.name).to.equal("Candidate 1");
      expect(winner.voteCount).to.equal(2);
    });

    it("Should not allow voting after election ends", async function () {
      await electionSystem.endElection();
      await votingToken.mint(voter3.address, 1);
      await votingToken.connect(voter3).approve(electionSystem.address, 1);

      await expect(
        electionSystem.connect(voter3).castVote(1)
      ).to.be.revertedWith("Election has ended");
    });
  });
});
