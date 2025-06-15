// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";


contract CrowdFund {
    address public owner;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalContributions;
    bool public goalReached;
    bool public ownerWithdrawn;

    error NotOwner(string reason);
    error DeadlineNotReached(string reason);
    error DeadLinePassed(string reason);
    error GoalNotReached(string reason);
    error GoalAlreadyReached(string reason);
    error NothingToRefund(string reason);
    error AlreadyWithdrawn(string reason);
    error ZeroContribution(string reason);

    mapping(address => uint256) public contributions;

    event Contribution(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalAmount);
    event OwnerWithdrew(uint256 amount);
    event RefundIssued(address indexed contributor, uint256 amount);

    constructor(uint256 _goal, uint256 _deadline) {
        owner = msg.sender;
        goal = _goal;
        deadline = _deadline;
    }

    modifier OnlyOwner() {
        if (msg.sender != owner) revert NotOwner("Only Owner Can Call This Function");
        _;
    }

    modifier beforeDeadline() {
        if (block.timestamp >= deadline) revert DeadLinePassed("Deadline Has Passed");
        _;
    }

    modifier afterDeadline() {
        if (block.timestamp < deadline) revert DeadlineNotReached("DeadLine Has Not Arrived");
        _;
    }

    function contribute() external payable beforeDeadline {
        if (msg.value == 0) revert ZeroContribution("Amount Must Be Larger Than Zero");

        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;

        emit Contribution(msg.sender, msg.value);

        if (totalContributions >= goal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalContributions);
        }
    }

    function OwnerWithdrawal() external OnlyOwner afterDeadline {
        if (!goalReached) revert GoalNotReached("Can't Withdraw, Goal Hasn't Been Met");
        if (ownerWithdrawn) revert AlreadyWithdrawn("You Have Already Withdrawn");

        ownerWithdrawn = true;
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);

        emit OwnerWithdrew(balance);
    }

    function refund() external afterDeadline {
        if (goalReached) revert GoalAlreadyReached("Goal Has Been Met, Can't Be Refunded");

        uint256 amount = contributions[msg.sender];
        if (amount == 0) revert NothingToRefund("You Have Nothing To Be Refunded");

        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit RefundIssued(msg.sender, amount);
    }

    function timeLeft() external view returns (uint256) {
        if (block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }

    function getMyContribution() external view returns (uint256) {
        return contributions[msg.sender];
    }
}
