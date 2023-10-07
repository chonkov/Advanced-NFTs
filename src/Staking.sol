// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {Context} from "lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {Ownable2Step, Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {RewardToken} from "./RewardToken.sol";

error InvalidCaller();
error InvalidOwner();

contract Staking is Context, Ownable2Step, IERC721Receiver {
    // Using uint96 in order to occupy only 1 slot. Max uint96 is high enough to do not allow overflow
    struct Deposit {
        address owner;
        uint96 lastRewardWithdrawal;
    }

    event TokenStaked(uint256 indexed tokenId, address operator, address from, bytes data);
    event SetRewardToken(address previoudRewardToken, address newRewardToken);
    event AcceptOwnership(address rewardToken);
    event Withdrawal(uint256 indexed tokenId, address indexed withdrawer);
    event RewardsClaimed(uint256 indexed tokenId, address indexed claimer, uint256 amount);

    address public immutable collection;
    address public rewardToken;
    mapping(uint256 => Deposit) public deposits;

    constructor(address _collection) Ownable(_msgSender()) {
        collection = _collection;
    }

    /**
     * @notice Allows the transfer of an NFT
     * @param _operator address Token transfered by this address
     * @param _from address Token transfered from this address
     * @param _tokenId uint256 ID of the token to deposit
     * @param _data Additionnal data
     * @return IERC721Receiver.onERC721Received.selector
     */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data)
        external
        returns (bytes4)
    {
        if (_msgSender() != address(collection)) {
            revert InvalidCaller();
        }
        deposits[_tokenId] = Deposit(_from, uint96(block.timestamp)); // Allowing initial owner of the NFT to be able to withdraw

        emit TokenStaked(_tokenId, _operator, _from, _data);
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice An approval is required before depositing, otherwise an error will be thrown
     * @param _tokenId uint256 ID of the token to deposit
     */
    function deposit(uint256 _tokenId) external {
        deposits[_tokenId] = Deposit(_msgSender(), uint96(block.timestamp));
        IERC721(collection).transferFrom(_msgSender(), address(this), _tokenId);

        emit TokenStaked(_tokenId, _msgSender(), _msgSender(), "");
    }

    /**
     * @notice Claim your rewards without withdrawing your NFT
     * @param _tokenId uint256 ID of the token to withdraw
     */
    function claimRewards(uint256 _tokenId) external {
        Deposit memory _deposit = deposits[_tokenId];
        if (_msgSender() != _deposit.owner) {
            revert InvalidOwner();
        }

        uint256 _calculatedRewards = calculateRewards(_deposit.lastRewardWithdrawal);
        _deposit.lastRewardWithdrawal = uint96(block.timestamp);
        RewardToken(rewardToken).mint(_msgSender(), _calculatedRewards);
        deposits[_tokenId] = _deposit;

        emit RewardsClaimed(_tokenId, _msgSender(), _calculatedRewards);
    }

    /**
     * @notice Withdraw your deposited NFT and obtain rewards
     * @param _tokenId uint256 ID of the token to withdraw
     */
    function withdraw(uint256 _tokenId) external {
        Deposit memory _deposit = deposits[_tokenId];
        if (_msgSender() != _deposit.owner) {
            revert InvalidOwner();
        }

        uint256 _calculatedRewards = calculateRewards(_deposit.lastRewardWithdrawal);
        RewardToken(rewardToken).mint(_msgSender(), _calculatedRewards);
        IERC721(collection).safeTransferFrom(address(this), _msgSender(), _tokenId);

        delete deposits[_tokenId];

        emit Withdrawal(_tokenId, _msgSender());
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

    /**
     * @notice The calculation is based on 10 tokens every 24 hours
     * @param _lastRewardWithdrawal Starting point for the calculation
     * @return The calculated reward
     */
    function calculateRewards(uint256 _lastRewardWithdrawal) public view returns (uint256) {
        uint256 _timeSinceLastWithdrawal = block.timestamp - _lastRewardWithdrawal;
        uint256 _calculatedRewards = _timeSinceLastWithdrawal * 10 ether / 1 days;
        return _calculatedRewards;
    }
}
