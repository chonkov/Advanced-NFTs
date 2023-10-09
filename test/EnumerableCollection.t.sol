// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {EnumerableCollection} from "../src/EnumerableCollection.sol";

contract EnumerableCollectionTest is Test {
    EnumerableCollection collection;
    address owner = address(123);

    function setUp() public {
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
}
