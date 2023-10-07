// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {Context} from "lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {Ownable2Step, Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {RewardToken} from "./RewardToken.sol";

contract Staking is Context, Ownable2Step, IERC721Receiver {
    event TokenStaked(uint256 indexed tokenId, address operator, address from, bytes data);
    event SetRewardToken(address previoudRewardToken, address newRewardToken);
    event AcceptOwnership(address rewardToken);

    address public immutable collection;
    address public rewardToken;
    mapping(uint256 => address) public tokenToOwner;

    constructor(address _collection) Ownable(_msgSender()) {
        collection = _collection;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        require(_msgSender() == address(collection));
        tokenToOwner[tokenId] = from; // Allowing initial owner of the NFT to be able to withdraw

        emit TokenStaked(tokenId, operator, from, data);
        return IERC721Receiver.onERC721Received.selector;
    }

    function setRewardToken(address newRewardToken) external onlyOwner {
        address previoudRewardToken = rewardToken;
        rewardToken = newRewardToken; // Set new reward token for the staked NFTs

        emit SetRewardToken(previoudRewardToken, newRewardToken);
    }

    function acceptOwnership(address _rewardToken) external onlyOwner {
        RewardToken(_rewardToken).acceptOwnership(); // Accept ownership of the token after first being approved

        emit AcceptOwnership(_rewardToken);
    }
}
