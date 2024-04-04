// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {RewardTokenUpgradeable} from "../src/upgradeable/RewardTokenUpgradeable.sol";
import {CollectionUpgradeable} from "../src/upgradeable/CollectionUpgradeable.sol";
import {StakingUpgradeable} from "../src/upgradeable/StakingUpgradeable.sol";
import {ERC1967Proxy} from "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";

contract DeployUUPSProxy is Script {
    function run() public {
        RewardTokenUpgradeable rewardTokenImplementation =
            RewardTokenUpgradeable(0x90193C961A926261B756D1E5bb255e67ff9498A1);
        CollectionUpgradeable collectionImplementation =
            CollectionUpgradeable(0xA8452Ec99ce0C64f20701dB7dD3abDb607c00496);
        StakingUpgradeable stakingImplementation = StakingUpgradeable(0xBb2180ebd78ce97360503434eD37fcf4a1Df61c3);

        vm.startBroadcast();

        bytes memory tokenData =
            abi.encodeCall(rewardTokenImplementation.initialize, ("Reward Token Name", "RTN", msg.sender));
        ERC1967Proxy tokenProxy = new ERC1967Proxy(address(rewardTokenImplementation), tokenData);

        //   string _name,
        //   string _symbol,
        //   uint256 _supply,
        //   uint256 _mintPrice,
        //   uint256 _discountPrice,
        //   bytes32 _merkleRoot,
        //   bytes32 _ticket,
        //   uint256 _currentTokenId,
        //   uint96 _fee
        //   bytes memory collectionData = abi.encodeCall(collectionImplementation.initialize, ());
        //   ERC1967Proxy collectionProxy = new ERC1967Proxy(address(collectionImplementation), collectionData);

        //   uint256 _dailyReward, address _collection, address _rewardToken
        //   bytes memory stakingData = abi.encodeCall(stakingImplementation.initialize, ());
        //   ERC1967Proxy stakingProxy = new ERC1967Proxy(address(stakingImplementation), stakingData);

        vm.stopBroadcast();

        console.log("UUPS Token Proxy Address:", address(tokenProxy));
    }
}
