// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {Collection} from "../src/Collection.sol";
import {Staking, Ownable} from "../src/Staking.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract StakingTest is Test {
    Collection public collection;
    Staking public staking;
    RewardToken public token;
    address owner = address(123);

    function setUp() public {
        vm.deal(owner, 5 ether);
        vm.startPrank(owner);
        collection =
            new Collection("MyNFT","MNFT", 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 250);
        collection.mint{value: 1 ether}();
        collection.mint{value: 1 ether}();
        staking = new Staking(address(collection));
        token = new RewardToken("MyToken","MTKN", address(staking));
        assertEq(staking.rewardToken(), address(0));
        staking.setRewardToken(address(token));
        vm.stopPrank();
    }

    function testSetUp() public {
        assertEq(staking.owner(), owner);
        assertEq(staking.rewardToken(), address(token));
        assertEq(staking.collection(), address(collection));
        assertEq(token.owner(), address(staking));
        assertEq(collection.ownerOf(1), owner);
        assertEq(collection.ownerOf(2), owner);
    }

    function testMintFail() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        token.mint(address(0), 0);
    }

    function testDirectNFTTransfer() public {
        vm.prank(owner);
        collection.safeTransferFrom(owner, address(staking), 2);

        assertEq(collection.ownerOf(2), address(staking));
        (address _owner, uint96 _timestamp) = staking.deposits(2);
        assertEq(_owner, owner);
        assertEq(_timestamp, uint96(block.timestamp));
    }

    function testDeposit() public {
        vm.startPrank(owner);
        collection.approve(address(staking), 2);
        staking.deposit(2);
        vm.stopPrank();

        assertEq(collection.ownerOf(2), address(staking));
        (address _owner, uint96 _timestamp) = staking.deposits(2);
        assertEq(_owner, owner);
        assertEq(_timestamp, uint96(block.timestamp));
    }

    function testClaimRewards() public {
        vm.prank(owner);
        collection.safeTransferFrom(owner, address(staking), 2);

        uint256 currentTimestamp = block.timestamp;
        (uint256 calculatedRewards,) = staking.calculateRewards(currentTimestamp);
        assertEq(calculatedRewards, 0);

        vm.warp(currentTimestamp + 1 days);

        (calculatedRewards,) = staking.calculateRewards(currentTimestamp);
        assertEq(calculatedRewards, 10 ether);

        currentTimestamp = block.timestamp;

        vm.prank(owner);
        staking.claimRewards(2);
        assertEq(token.balanceOf(owner), 10 ether);
        (, uint96 timestamp) = staking.deposits(2);
        assertEq(timestamp, currentTimestamp);
    }

    function testWithdraw() public {
        vm.prank(owner);
        collection.safeTransferFrom(owner, address(staking), 2);
        vm.warp(block.timestamp + (3600 * 47));

        vm.prank(owner);
        staking.withdraw(2);

        (address _owner, uint96 timestamp) = staking.deposits(2);
        assertEq(_owner, address(0));
        assertEq(timestamp, 0);
        assertEq(token.balanceOf(owner), 10 ether);
    }

    function testSetRewardToken() public {
        vm.prank(owner);
        staking.setRewardToken(address(token));
    }

    function testSetRewardTokenFail() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        staking.setRewardToken(address(0));

        vm.prank(owner);
        vm.expectRevert(Staking.Staking_Zero_Address.selector);
        staking.setRewardToken(address(0));
    }

    function testTransferOwnership() public {
        vm.startPrank(owner);
        staking.transferOwnership(address(token), owner);
        assertEq(token.owner(), address(staking));

        token.acceptOwnership();
        assertEq(token.owner(), owner);

        token.transferOwnership(address(staking));
        assertEq(token.pendingOwner(), address(staking));

        staking.acceptOwnership(address(token));
        assertEq(token.owner(), address(staking));
    }

    function testTransferOwnershipFail() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        staking.transferOwnership(address(token), owner);
    }

    function testOnERC721ReceivedFail() public {
        vm.prank(owner);
        vm.expectRevert(Staking.Staking_Invalid_Caller.selector);
        staking.onERC721Received(owner, owner, 2, "");
    }

    function testClaimRewardsFail() public {
        vm.prank(address(456));
        vm.expectRevert(Staking.Staking_Invalid_Owner.selector);
        staking.claimRewards(2);
    }

    function testWithdrawFail() public {
        vm.prank(address(456));
        vm.expectRevert(Staking.Staking_Invalid_Owner.selector);
        staking.withdraw(2);
    }

    function testAcceptOwnershipFail() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        staking.acceptOwnership(address(token));

        vm.prank(owner);
        vm.expectRevert();
        staking.acceptOwnership(address(token));
    }

    function testDeploymentFail() public {
        vm.expectRevert();
        new Staking(address(0));
    }
}
