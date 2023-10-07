// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable2Step, Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract RewardToken is Ownable2Step, ERC20 {
    constructor(string memory _name, string memory _symbol, address _owner) Ownable(_owner) ERC20(_name, _symbol) {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    // Potentially useful?
    //  function burn(address _from, uint256 _amount) external onlyOwner {
    //      _burn(_from, _amount);
    //      emit Transfer(_from, address(0), _amount);
    //  }
}
