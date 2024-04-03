// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable2Step, Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {RewardToken} from "./RewardToken.sol";

contract Staking is Ownable2Step, IERC721Receiver {
    // Using uint96 in order to occupy only 1 slot. Max uint96 is high enough to do not allow overflow
    struct Deposit {
        address owner;
        uint96 lastRewardWithdrawal;
    }

    error Staking_Invalid_Caller();
    error Staking_Invalid_Owner();
    error Staking_Zero_Address();

    event TokenStaked(uint256 indexed tokenId, address operator, address from, bytes data);
    event SetRewardToken(address previousRewardToken, address newRewardToken);
    event AcceptedOwnership(address rewardToken);
    event Withdrawal(uint256 indexed tokenId, address indexed withdrawer);
    event RewardsClaimed(uint256 indexed tokenId, address indexed claimer, uint256 amount);

    //  uint256 constant SECONDS_IN_ONE_DAY = 86_400; // Remove it
    uint256 constant DAILY_REWARD = 10 ether; // 10 tokens, assuming the token has 18 decimal places (USDT has only 6)
    address public immutable collection;
    address public rewardToken;
    mapping(uint256 => Deposit) public deposits;

    constructor(address _collection) Ownable(_msgSender()) {
        if (address(_collection) == address(0)) revert Staking_Zero_Address();
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
            revert Staking_Invalid_Caller();
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
        address _rewardToken = rewardToken;
        if (_msgSender() != _deposit.owner) revert Staking_Invalid_Owner();

        (uint256 _calculatedRewards, uint256 _timeSinceLastWithdrawal) = calculateRewards(_deposit.lastRewardWithdrawal);
        // uint96 _withdrawalTimestamp = uint96(block.timestamp - _deposit.lastRewardWithdrawal);
        _deposit.lastRewardWithdrawal += uint96(_timeSinceLastWithdrawal);

        deposits[_tokenId] = _deposit;

        RewardToken(_rewardToken).mint(_msgSender(), _calculatedRewards);

        emit RewardsClaimed(_tokenId, _msgSender(), _calculatedRewards);
    }

    /**
     * @notice Withdraw your deposited NFT and obtain rewards
     * @param _tokenId uint256 ID of the token to withdraw
     */
    function withdraw(uint256 _tokenId) external {
        Deposit memory _deposit = deposits[_tokenId];
        if (_msgSender() != _deposit.owner) revert Staking_Invalid_Owner();

        (uint256 _calculatedRewards,) = calculateRewards(_deposit.lastRewardWithdrawal);
        delete deposits[_tokenId];

        RewardToken(rewardToken).mint(_msgSender(), _calculatedRewards);
        IERC721(collection).safeTransferFrom(address(this), _msgSender(), _tokenId);

        emit Withdrawal(_tokenId, _msgSender());
    }

    function setRewardToken(address newRewardToken) external onlyOwner {
        if (newRewardToken == address(0)) revert Staking_Zero_Address();

        address previousRewardToken = rewardToken;
        rewardToken = newRewardToken; // Set new reward token for the staked NFTs

        emit SetRewardToken(previousRewardToken, newRewardToken);
    }

    function acceptOwnership(address _rewardToken) external onlyOwner {
        RewardToken(_rewardToken).acceptOwnership(); // Accept ownership of the token after first being approved

        emit AcceptedOwnership(_rewardToken);
    }

    function transferOwnership(address _rewardToken, address _newOwner) external onlyOwner {
        RewardToken(_rewardToken).transferOwnership(_newOwner); // Accept ownership of the token after first being approved
    }

    /**
     * @notice The calculation is based on 10 tokens every 24 hours
     * @param _lastRewardWithdrawal Starting point for the calculation
     * @return The calculated reward
     */
    function calculateRewards(uint256 _lastRewardWithdrawal) public view returns (uint256, uint256) {
        // Let's assume as an exaple that block.timestamp == 1,900,000 and _lastRewardWithdrawal == 1,000,000
        // and one day has 100,000 second, rather than 86,400. DAILY_REWARD == 10 ether or 10 tokens per day (token has 18 decimals)
        uint256 _timeSinceLastWithdrawal = block.timestamp - _lastRewardWithdrawal; // 1,999,000 - 1,000,000 = 999,000
        uint256 _calculatedRewards = _timeSinceLastWithdrawal / 1 days * DAILY_REWARD; // 999,000 / 100.000 = 9 * 10 ether
        return (_calculatedRewards, _timeSinceLastWithdrawal);
    }
}
