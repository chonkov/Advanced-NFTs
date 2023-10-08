// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract Collection is ERC721 {
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _mint(msg.sender, 1);
        _mint(msg.sender, 2);
    }
}
