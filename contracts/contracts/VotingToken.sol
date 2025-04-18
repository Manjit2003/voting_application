// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingToken is ERC20, Ownable {
    constructor() ERC20("Voting Token", "VOTE") Ownable(msg.sender) {}

    // Only admin can mint tokens to voters
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Override transfer functions to prevent transfers between users
    function transfer(address, uint256) public pure override returns (bool) {
        revert("Transfers are not allowed");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert("Transfers are not allowed");
    }
}
