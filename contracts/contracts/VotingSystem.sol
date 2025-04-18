// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VotingSystem is Ownable, Pausable, ReentrancyGuard {
    // Structs
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votingCoin;
        bytes32 voteHash;
    }

    struct Candidate {
        string name;
        string constituency;
        uint256 voteCount;
    }

    // State variables
    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    
    // Events
    event VoterRegistered(address indexed voter);
    event VoteCast(address indexed voter, bytes32 voteHash);
    event CandidateAdded(uint256 indexed candidateId, string name, string constituency);

    constructor() Ownable(msg.sender) {
    }

    // Admin functions
    function addCandidate(string memory name, string memory constituency) external onlyOwner {
        candidates.push(Candidate({
            name: name,
            constituency: constituency,
            voteCount: 0
        }));
        emit CandidateAdded(candidates.length - 1, name, constituency);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Voter functions
    function registerVoter() external whenNotPaused {
        require(!voters[msg.sender].isRegistered, "Voter already registered");
        
        voters[msg.sender] = Voter({
            isRegistered: true,
            hasVoted: false,
            votingCoin: 1,
            voteHash: bytes32(0)
        });
        
        emit VoterRegistered(msg.sender);
    }

    function castVote(uint256 candidateId) external whenNotPaused nonReentrant {
        require(voters[msg.sender].isRegistered, "Voter not registered");
        require(!voters[msg.sender].hasVoted, "Already voted");
        require(voters[msg.sender].votingCoin == 1, "No voting coin available");
        require(candidateId < candidates.length, "Invalid candidate");

        // Create vote hash
        bytes32 voteHash = keccak256(abi.encodePacked(msg.sender, candidateId, block.timestamp));
        
        // Update voter status
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votingCoin = 0;
        voters[msg.sender].voteHash = voteHash;
        
        // Update candidate vote count
        candidates[candidateId].voteCount++;
        
        emit VoteCast(msg.sender, voteHash);
    }

    // View functions
    function getCandidateCount() external view returns (uint256) {
        return candidates.length;
    }

    function getVoterStatus(address voter) external view returns (bool isRegistered, bool hasVoted, uint256 votingCoin) {
        Voter memory v = voters[voter];
        return (v.isRegistered, v.hasVoted, v.votingCoin);
    }

    function verifyVote(address voter, bytes32 voteHash) external view returns (bool) {
        return voters[voter].voteHash == voteHash;
    }
} 