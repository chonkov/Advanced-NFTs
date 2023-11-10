// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {EnumerableCollection, Ownable} from "../src/EnumerableCollection.sol";

contract Mock {
    function mock(address collection) external {
        EnumerableCollection(collection).withdrawEther();
    }

    receive() external payable {
        revert();
    }
}

contract EnumerableCollectionTest is Test {
    EnumerableCollection collection;
    address owner = address(123);
    Mock mock;

    function setUp() public {
        mock = new Mock();
        vm.prank(owner);
        collection = new EnumerableCollection("MyEnumerableCollection", "MEC");
    }

    function testPrimeTokensBy() public {
        vm.deal(owner, 100 ether);
        vm.startPrank(owner);
        vm.expectRevert("Invalid MINT_PRICE");
        collection.mint{value: (1 ether + 1)}();

        for (uint256 i = 0; i < 20; i++) {
            collection.mint{value: 1 ether}();
        }

        vm.expectRevert("CAN NOT mint more than SUPPLY");
        collection.mint{value: 1 ether}();

        assertEq(collection.balanceOf(owner), 20);
        assertEq(collection.primeTokensBy(owner), 8);

        collection.withdrawEther();
        assertEq(address(collection).balance, 0);
    }

    function testPrimeTokensEdgeCases() public {
        vm.deal(owner, 100 ether);
        vm.startPrank(owner);

        collection.mint{value: 1 ether}();

        assertEq(collection.balanceOf(owner), 1);
        assertEq(collection.primeTokensBy(owner), 0);

        collection.mint{value: 1 ether}();

        assertEq(collection.balanceOf(owner), 2);
        assertEq(collection.primeTokensBy(owner), 1);
    }

    function testWithdrawEtherFail() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        collection.withdrawEther();

        vm.deal(owner, 100 ether);
        vm.startPrank(owner);

        for (uint256 i = 0; i < 20; i++) {
            collection.mint{value: 1 ether}();
        }

        collection.transferOwnership(address(mock));
        vm.stopPrank();

        vm.expectRevert("Unsuccessful transfer");
        mock.mock(address(collection));
    }
}
