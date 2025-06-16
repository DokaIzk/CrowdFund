// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {CrowdFund} from "../src/CrowdFunding.sol";

contract CrowdFundTest is Test {
    CrowdFund public crowdfunding;
    address owner;
    address contributor1;
    address contributor2;
    uint8 constant DECIMALS = 18;
    uint256 constant GOAL = 1000000 * (10 ** DECIMALS);

    function setUp() public {
        owner = address(this);
        contributor1 = address(0x123);
        contributor2 = address(0x124);

        crowdfunding = new CrowdFund(GOAL, block.timestamp + 7 days);
    }

    function testContributeAndCheckBalance() public {
        vm.deal(contributor1, 5 * (10 ** DECIMALS));
        vm.prank(contributor1);
        crowdfunding.contribute{value: 5 * (10 ** DECIMALS)}();

        vm.prank(contributor1);
        uint256 amount = crowdfunding.getMyContribution();
        assertEq(amount, 5 * (10 ** DECIMALS));
    }

    function testGoalReached() public {
        uint256 contribution = GOAL / 2;

        vm.deal(contributor1, contribution);
        vm.deal(contributor2, contribution);

        vm.prank(contributor1);
        crowdfunding.contribute{value: contribution}();

        vm.prank(contributor2);
        crowdfunding.contribute{value: contribution}();

        assertTrue(crowdfunding.goalReached());
    }

    function testOwnerWithdrawAfterGoalMet() public {
        vm.deal(contributor1, GOAL);
        vm.prank(contributor1);
        crowdfunding.contribute{value: GOAL}();

        vm.warp(block.timestamp + 9 days);

        vm.prank(owner);
        crowdfunding.OwnerWithdrawal();

        assertTrue(crowdfunding.ownerWithdrawn());
    }

    function testRefundIfGoalNotMet() public {
        vm.deal(contributor2, 2 * (10 ** DECIMALS));
        vm.prank(contributor2);
        crowdfunding.contribute{value: 2 * (10 ** DECIMALS)}();

        vm.warp(block.timestamp + 9 days);

        vm.prank(contributor2);
        uint256 before = contributor2.balance;
        crowdfunding.refund();
        assertEq(contributor2.balance, before + 2 * (10 ** DECIMALS));
    }

    function testCannotContributeAfterDeadline() public {
        vm.warp(block.timestamp + 11 days);

        vm.deal(contributor1, 1 * (10 ** DECIMALS));
        vm.prank(contributor1);
        vm.expectRevert(abi.encodeWithSelector(CrowdFund.DeadLinePassed.selector, "Deadline Has Passed"));
        crowdfunding.contribute{value: 1 * (10 ** DECIMALS)}();
    }

    function testCannotRefundIfNothing() public {
        vm.warp(block.timestamp + 11 days);

        vm.prank(contributor1);
        vm.expectRevert(abi.encodeWithSelector(CrowdFund.NothingToRefund.selector, "You Have Nothing To Be Refunded"));
        crowdfunding.refund();
    }
}
