// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC721Enumerable} from "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library PrimeNumbersEnumerable {
    /**
     * @notice This function is used to calculate the number of prime number token indexes owned by an address
     * @param _collection address Address on which the algorithm is performed
     * @param _owner address Address to calculate the number of prime token indexes for
     * @return uint256 The number of prime number indexes owned by `_owner`
     */
    function enumeratePrimeNumberTokensForOwner(ERC721Enumerable _collection, address _owner)
        external
        view
        returns (uint256)
    {
        uint256 balanceOfOwner = _collection.balanceOf(_owner);
        uint256 primeNumbersBalance = 0;

        for (uint256 i = 0; i < balanceOfOwner;) {
            uint256 tokenNumber = _collection.tokenOfOwnerByIndex(_owner, i);
            unchecked {
                ++i;
                // 1 is not considered a prime number
                if (tokenNumber == 1) {
                    continue;
                }

                // set 2 and 3 as prime numbers
                if (tokenNumber == 2) {
                    ++primeNumbersBalance;
                    continue;
                }

                if (tokenNumber % 2 == 0) {
                    // if even number, not a Prime
                    continue;
                }

                // Only the odd numbers need to be tested
                // Algorithm could be optimized for large numbers if `tokenNumber` is replaced by sqrt(tokenNumber)
                bool isPrime = true;
                for (uint256 j = 3; j * j <= tokenNumber; j = j + 2) {
                    if (tokenNumber % j == 0) {
                        isPrime = false;
                        break;
                    }
                }

                if (isPrime) {
                    ++primeNumbersBalance;
                }
            }
        }
        return primeNumbersBalance;
    }
}
