// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingToken is ERC20, Ownable {
    constructor() ERC20("Voting Token", "VOTE") Ownable(msg.sender) {}
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
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
