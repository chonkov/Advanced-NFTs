// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {Collection} from "../src/Collection.sol";
import {Staking} from "../src/Staking.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract StakingTest is Test {
    Collection public collection;
    Staking public staking;
    RewardToken public token;
    address owner = address(123);
    bytes32 merkleRoot;
    bytes32[14] proofs;
    bytes32[] merkleProofUser1;
    bytes32[] merkleProofUser6;

    address user1 = address(111);
    address user2 = address(222);
    address user3 = address(333);
    address user4 = address(444);
    address user5 = address(555);
    address user6 = address(666);
    address user7 = address(777);
    address user8 = address(888);

    function computeMerkleRoot() public returns (bytes32) {
        proofs[0] = keccak256(abi.encode(user1, 1));
        proofs[1] = keccak256(abi.encode(user2, 2));
        proofs[2] = keccak256(abi.encode(user3, 3));
        proofs[3] = keccak256(abi.encode(user4, 4));
        proofs[4] = keccak256(abi.encode(user5, 5));
        proofs[5] = keccak256(abi.encode(user6, 6));
        proofs[6] = keccak256(abi.encode(user7, 7));
        proofs[7] = keccak256(abi.encode(user8, 8));

        proofs[8] = keccak256(abi.encode(proofs[0], proofs[1]));
        proofs[9] = keccak256(abi.encode(proofs[2], proofs[3]));
        proofs[10] = keccak256(abi.encode(proofs[4], proofs[5]));
        proofs[11] = keccak256(abi.encode(proofs[6], proofs[7]));

        proofs[12] = keccak256(abi.encode(proofs[8], proofs[9]));
        proofs[13] = keccak256(abi.encode(proofs[10], proofs[11]));

        return keccak256(abi.encode(proofs[12], proofs[13]));
    }

    function updateMerkleProofUser1() public {
        merkleProofUser1 = [proofs[1], proofs[9], proofs[13]];
    }

    function updateMerkleProofUser6() public {
        merkleProofUser6 = [proofs[4], proofs[11], proofs[12]];
    }

    function setUp() public {
        merkleRoot = computeMerkleRoot();
        updateMerkleProofUser1();
        updateMerkleProofUser6();

        vm.deal(owner, 5 ether);
        vm.startPrank(owner);
        collection = new Collection("MyNFT","MNFT", merkleRoot, 250);
        //   collection.mint{value: 1 ether}();
        //   collection.mint{value: 1 ether}();
        staking = new Staking(address(collection));
        token = new RewardToken("MyToken","MTKN", address(staking));
        assertEq(staking.rewardToken(), address(0));
        staking.setRewardToken(address(token));
        vm.stopPrank();

        vm.deal(user1, 1 ether);
        vm.prank(user1);
        collection.presaleMint{value: 0.5 ether}(1, merkleProofUser1);

        vm.deal(user6, 1 ether);
        vm.prank(user6);
        collection.presaleMint{value: 0.5 ether}(6, merkleProofUser6);

        vm.prank(owner);
        collection.mint{value: 1 ether}();
    }

    function testSetUp() public {
        assertEq(staking.owner(), owner);
        assertEq(staking.rewardToken(), address(token));
        assertEq(staking.collection(), address(collection));
        assertEq(token.owner(), address(staking));
        assertEq(collection.ownerOf(1), user1);
        assertEq(collection.ownerOf(2), user6);
        assertEq(collection.ownerOf(3), owner);
    }

    function testDirectNFTTransfer() public {
        vm.prank(owner);
        collection.safeTransferFrom(owner, address(staking), 3);

        assertEq(collection.ownerOf(3), address(staking));
        (address _owner, uint96 _timestamp) = staking.deposits(3);
        assertEq(_owner, owner);
        assertEq(_timestamp, uint96(block.timestamp));
    }

    function testDeposit() public {
        vm.startPrank(owner);
        collection.approve(address(staking), 3);
        staking.deposit(3);
        vm.stopPrank();

        assertEq(collection.ownerOf(3), address(staking));
        (address _owner, uint96 _timestamp) = staking.deposits(3);
        assertEq(_owner, owner);
        assertEq(_timestamp, uint96(block.timestamp));
    }

    function testClaimRewards() public {
        vm.prank(owner);
        collection.safeTransferFrom(owner, address(staking), 3);

        uint256 currentTimestamp = block.timestamp;
        uint256 calculatedRewards = staking.calculateRewards(currentTimestamp);
        assertEq(calculatedRewards, 0);

        vm.warp(currentTimestamp + (3600 * 24));

        currentTimestamp = block.timestamp;
        calculatedRewards = staking.calculateRewards(1);
        assertEq(calculatedRewards, 10 ether);

        vm.prank(owner);
        staking.claimRewards(3);
        assertEq(token.balanceOf(owner), 10 ether);
    }

    function testWithdraw() public {
        vm.prank(owner);
        collection.safeTransferFrom(owner, address(staking), 3);
        vm.warp(block.timestamp + (3600 * 47));

        vm.prank(owner);
        staking.withdraw(3);

        (address _owner, uint96 timestamp) = staking.deposits(3);
        assertEq(_owner, address(0));
        assertEq(timestamp, 0);
        assertEq(token.balanceOf(owner), 10 ether);
    }

    function testSetRewardToken() public {
        vm.prank(owner);
        staking.setRewardToken(address(token));
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

    function testOnERC721ReceivedFail() public {
        vm.prank(owner);
        vm.expectRevert();
        staking.onERC721Received(owner, owner, 2, "");
    }

    function testClaimRewardsFail() public {
        vm.prank(address(456));
        vm.expectRevert();
        staking.claimRewards(2);
    }

    function testWithdrawFail() public {
        vm.prank(address(456));
        vm.expectRevert();
        staking.withdraw(2);
    }

    function testAcceptOwnershipFail() public {
        vm.prank(owner);
        vm.expectRevert();
        staking.acceptOwnership(address(token));
    }
}
