// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC721Enumerable} from "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {PrimeNumbersEnumerable} from "./PrimeNumbersEnumerable.sol";

contract EnumerableCollection is Ownable, ERC721Enumerable {
    using PrimeNumbersEnumerable for ERC721Enumerable;

    uint256 public constant MINT_PRICE = 1 ether;
    uint256 public constant SUPPLY = 21;
    uint256 public currentTokenId = 1;

    constructor(string memory _name, string memory _symbol) Ownable(_msgSender()) ERC721(_name, _symbol) {}

    /**
     * @notice Mint NFT with price = MINT_PRICE (1 ether)
     * @return Incremented `currentTokenId`
     */
    function mint() public payable returns (uint256) {
        require(msg.value == MINT_PRICE, "Invalid MINT_PRICE");

        uint256 _currentTokenId = currentTokenId;
        require(_currentTokenId < SUPPLY, "CAN NOT mint more than SUPPLY");
        unchecked {
            currentTokenId = _currentTokenId + 1;
        }
        _safeMint(_msgSender(), _currentTokenId);

        return _currentTokenId;
    }

    function primeTokensBy(address _owner) public view returns (uint256) {
        return ERC721Enumerable(this).enumeratePrimeNumberTokensForOwner(_owner);
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
