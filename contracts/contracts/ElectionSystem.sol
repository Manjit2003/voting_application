// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./VotingToken.sol";

contract ElectionSystem is Ownable {
    struct Candidate {
        string name;
        uint256 voteCount;
        bool exists;
    }

    VotingToken public votingToken;
    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public hasVoted;
    uint256 public candidateCount;
    bool public electionEnded;
    uint256 public winningCandidateId;

    event CandidateAdded(uint256 indexed candidateId, string name);
    event VoteCast(address indexed voter, uint256 indexed candidateId);
    event ElectionEnded(uint256 indexed winningCandidateId, uint256 voteCount);

    constructor(address _votingToken) Ownable(msg.sender) {
        votingToken = VotingToken(_votingToken);
        electionEnded = false;
    }

    modifier electionOngoing() {
        require(!electionEnded, "Election has ended");
        _;
    }

    // Only admin can add candidates
    function addCandidate(
        string memory _name
    ) external onlyOwner electionOngoing {
        require(bytes(_name).length > 0, "Name cannot be empty");
        candidateCount++;
        candidates[candidateCount] = Candidate(_name, 0, true);
        emit CandidateAdded(candidateCount, _name);
    }

    // Voters can cast their vote
    function castVote(uint256 _candidateId) external electionOngoing {
        require(candidates[_candidateId].exists, "Candidate does not exist");
        require(!hasVoted[msg.sender], "Already voted");
        require(votingToken.balanceOf(msg.sender) > 0, "No voting tokens");

        hasVoted[msg.sender] = true;
        candidates[_candidateId].voteCount++;

        // Burn the voting token after use
        votingToken.transferFrom(msg.sender, address(this), 1);

        emit VoteCast(msg.sender, _candidateId);
    }

    // Admin can end the election and declare winner
    function endElection() external onlyOwner electionOngoing {
        require(candidateCount > 0, "No candidates");

        uint256 maxVotes = 0;
        uint256 winnerId = 0;

        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winnerId = i;
            }
        }

        winningCandidateId = winnerId;
        electionEnded = true;

        emit ElectionEnded(winnerId, maxVotes);
    }

    // View functions
    function getCandidate(
        uint256 _candidateId
    ) external view returns (string memory name, uint256 voteCount) {
        require(candidates[_candidateId].exists, "Candidate does not exist");
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.name, candidate.voteCount);
    }

    function getWinner()
        external
        view
        returns (string memory name, uint256 voteCount)
    {
        require(electionEnded, "Election not ended");
        require(winningCandidateId > 0, "No winner");
        Candidate memory winner = candidates[winningCandidateId];
        return (winner.name, winner.voteCount);
    }
}
