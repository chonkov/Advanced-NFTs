// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {
    Ownable2StepUpgradeable,
    OwnableUpgradeable
} from "lib/openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract RewardTokenUpgradeable is Ownable2StepUpgradeable, ERC20Upgradeable, UUPSUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata _name, string calldata _symbol, address _owner) external initializer {
        __Ownable_init(_owner);
        __ERC20_init(_name, _symbol);
        __UUPSUpgradeable_init();
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
