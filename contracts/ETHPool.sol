// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ETHPool is Ownable, AccessControl {
    bytes32 public constant TEAM_MEMBER = keccak256("TEAM_MEMBER");

    mapping (address => uint256) public user;
    uint totalShares;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);

    constructor() {
        _grantRole(TEAM_MEMBER, msg.sender);
    }

    function setTeamMember(address _team) external onlyOwner {
        _setupRole(TEAM_MEMBER, _team);
    }

    /// @notice withdraw deposits along with their share of rewards considering the time when they deposited
    function withdraw() public {
        uint totalEth = address(this).balance;
        console.log("totalEth", totalEth);
        console.log("totalShares", totalShares);
        console.log("user[msg.sender]", user[msg.sender]);
        uint amount = user[msg.sender] * totalEth / totalShares;
        totalShares -= user[msg.sender];
        user[msg.sender] = 0;
        (bool success, ) = msg.sender.call{
            value: amount
        }("");
        require(success, "EthPool: Transfer failed.");
        emit Withdraw(msg.sender, user[msg.sender]);
    }

    /// @notice deposit Eth to the pool
    function deposit() public payable {
        uint amount = msg.value;
        uint totalEth = address(this).balance - amount;
        if (totalShares == 0 || totalEth == 0) {
            totalShares += amount;
            user[msg.sender] += amount;
        } else {
            uint what = amount * totalShares / totalEth;
            totalShares += what;
            user[msg.sender] += what;
        }
        
        emit Deposit(msg.sender, amount);
    }

    /// @notice team deposit rewards
    function depositRewards() public payable onlyRole(TEAM_MEMBER) {
    }

    receive() external payable {
        revert();
    }
}
