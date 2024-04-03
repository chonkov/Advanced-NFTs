// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC721Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {ERC2981Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/common/ERC2981Upgradeable.sol";
import {MerkleProof} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {
    Ownable2StepUpgradeable,
    OwnableUpgradeable
} from "lib/openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";

contract Collection is Ownable2StepUpgradeable, ERC721Upgradeable, ERC2981Upgradeable {
    using MerkleProof for bytes32[];

    event Withdrawal(address owner); // add address, because owner could be changed later

    uint256 public constant SUPPLY = 21; // Intentional
    uint256 public constant MINT_PRICE = 1 ether;
    uint256 public constant DISCOUNT_PRICE = 0.5 ether; // If a minter is included in the merkle root
    bytes32 public merkleRoot;
    uint256 public ticket;
    uint256 public currentTokenId;

    function initialize(
        string memory _name,
        string memory _symbol,
        bytes32 _merkleRoot,
        bytes32 _ticket,
        uint256 _currentTokenId,
        uint96 _fee
    ) external initializer {
        __Ownable_init(_msgSender());
        __ERC721_init(_name, _symbol);
        merkleRoot = _merkleRoot;
        ticket = uint256(_ticket);
        currentTokenId = _currentTokenId;
        _setDefaultRoyalty(_msgSender(), _fee);
    }

    /**
     * @notice Mint NFT with price = MINT_PRICE (1 ether)
     * @return Incremented `currentTokenId`
     */
    function mint() external payable returns (uint256) {
        require(msg.value == MINT_PRICE, "Invalid MINT_PRICE");

        uint256 _currentTokenId = currentTokenId;
        require(_currentTokenId < SUPPLY, "CAN NOT mint more than SUPPLY");
        unchecked {
            currentTokenId = _currentTokenId + 1;
        }
        _safeMint(_msgSender(), _currentTokenId);

        return _currentTokenId;
    }

    function presaleMint(uint256 _ticket, bytes32[] memory _merkleProof) external payable returns (uint256) {
        bytes32 leaf = keccak256(abi.encode(_msgSender(), _ticket));
        _ticket--; // Token indexes start at 1, but tickets at 0
        uint256 ticketCached = ticket;
        require(_merkleProof.verify(merkleRoot, leaf), "Invalid proof");
        require(msg.value == DISCOUNT_PRICE, "Invalid DISCOUNT_PRICE");
        require((ticketCached >> _ticket & uint256(1)) == 1, "Ticket already used");
        ticketCached = ticketCached & ~(uint256(1) << _ticket);
        ticket = ticketCached;

        uint256 _currentTokenId = currentTokenId;
        require(_currentTokenId < SUPPLY, "CAN NOT mint more than SUPPLY");
        unchecked {
            currentTokenId = _currentTokenId + 1;
        }
        _safeMint(_msgSender(), _currentTokenId);

        return _currentTokenId;
    }

    /**
     * @notice Standard Interface declaration
     * @dev ERC-165 support
     * @param _interfaceId bytes4 The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function withdrawEther() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Unsuccessful transfer");

        emit Withdrawal(msg.sender);
    }
}
