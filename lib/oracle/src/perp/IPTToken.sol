// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


//avantifi Track token
interface IPTToken is IERC20 {
    function mint(address account) external;
    function balanceOf(address account) external view returns (uint256);
}
