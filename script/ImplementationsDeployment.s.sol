// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {RewardTokenUpgradeable} from "../src/upgradeable/RewardTokenUpgradeable.sol";
import {CollectionUpgradeable} from "../src/upgradeable/CollectionUpgradeable.sol";
import {StakingUpgradeable} from "../src/upgradeable/StakingUpgradeable.sol";
import "forge-std/Script.sol";

contract ImplementationsDeployment is Script {
    function run() public {
        vm.startBroadcast();

        RewardTokenUpgradeable rewardTokenImplementation = new RewardTokenUpgradeable();
        CollectionUpgradeable collectionImplementation = new CollectionUpgradeable();
        StakingUpgradeable stakingImplementation = new StakingUpgradeable();

        vm.stopBroadcast();

        console.log("Token Implementation Address:", address(rewardTokenImplementation));
        console.log("Collection Implementation Address:", address(collectionImplementation));
        console.log("Staking Implementation Address:", address(stakingImplementation));
    }
}
