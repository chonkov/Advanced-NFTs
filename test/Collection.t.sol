// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC2981} from "lib/openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Collection} from "../src/Collection.sol";

contract Dummy {
    function acceptOwnership(address collection) external {
        Collection(collection).acceptOwnership();
    }

    function withdrawEther(address collection) external {
        Collection(collection).withdrawEther();
    }

    receive() external payable {
        revert();
    }
}

contract CollectionTest is Test {
    Collection collection;
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
        vm.prank(owner);
        collection = new Collection("MyNFT","MNFT", merkleRoot, 250);

        vm.deal(user1, 1 ether);
        vm.prank(user1);
        collection.presaleMint{value: 0.5 ether}(1, merkleProofUser1);
    }

    function testSetUp() public {
        assertEq(collection.owner(), owner);
        assertEq(collection.ownerOf(1), user1);
        assertEq(collection.merkleRoot(), merkleRoot);
        assertEq(type(uint256).max - collection.ticket(), 1);
    }

    function testRoyaltyInfo() public {
        (address receiver, uint256 amount) = collection.royaltyInfo(2, 10_000);
        assertEq(receiver, owner);
        assertEq(amount, 250);
    }

    function testMint() public {
        vm.prank(owner);
        collection.mint{value: 1 ether}();
        assertEq(collection.ownerOf(2), owner);
    }

    function testPresaleMint() public {
        vm.deal(user6, 1 ether);
        vm.prank(user6);
        collection.presaleMint{value: 0.5 ether}(6, merkleProofUser6);
        assertEq(collection.ownerOf(2), user6);
    }

    function testSupportsInterface() public {
        assertEq(collection.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(collection.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(collection.supportsInterface(type(IERC2981).interfaceId), true);
        assertEq(collection.supportsInterface(type(IERC20).interfaceId), false);
    }

    function testWithdrawEther() public {
        uint256 balance = owner.balance;
        uint256 conttactBalance = address(collection).balance;

        vm.prank(owner);
        collection.withdrawEther();

        assertEq(owner.balance, conttactBalance + balance);
        assertEq(address(collection).balance, 0);
    }

    function testMintFail() public {
        vm.prank(owner);
        vm.expectRevert("Invalid MINT_PRICE");
        collection.mint{value: (1 ether + 1)}();

        vm.store(address(collection), bytes32(uint256(11)), bytes32(uint256(21)));
        vm.prank(owner);
        vm.expectRevert("CAN NOT mint more than SUPPLY");
        collection.mint{value: 1 ether}();
    }

    function testPresaleMintFail() public {
        vm.deal(user6, 5 ether);

        vm.startPrank(user6);
        vm.expectRevert("Invalid proof");
        collection.presaleMint{value: 0.5 ether}(6 + 1, merkleProofUser6);

        bytes32 copy = merkleProofUser6[0];
        merkleProofUser6[0] = merkleProofUser6[1];
        vm.expectRevert("Invalid proof");
        collection.presaleMint{value: 0.5 ether}(6, merkleProofUser6);

        merkleProofUser6[0] = copy;
        vm.expectRevert("Invalid DISCOUNT_PRICE");
        collection.presaleMint{value: (0.5 ether + 1)}(6, merkleProofUser6);

        bytes32 value = vm.load(address(collection), bytes32(uint256(11)));
        vm.store(address(collection), bytes32(uint256(11)), bytes32(uint256(21)));
        vm.expectRevert("CAN NOT mint more than SUPPLY");
        collection.presaleMint{value: 0.5 ether}(6, merkleProofUser6);

        vm.store(address(collection), bytes32(uint256(11)), value);
        collection.presaleMint{value: 0.5 ether}(6, merkleProofUser6);
        assertEq(collection.ownerOf(2), user6);

        vm.expectRevert("Ticket already used");
        collection.presaleMint{value: 0.5 ether}(6, merkleProofUser6);
    }

    function testWithdrawEtherFail() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        collection.withdrawEther();

        Dummy dummy = new Dummy();

        vm.startPrank(owner);
        collection.transferOwnership(address(dummy));
        dummy.acceptOwnership(address(collection));
        assertEq(collection.owner(), address(dummy));

        vm.expectRevert("Unsuccessful transfer");
        dummy.withdrawEther(address(collection));
    }
}
