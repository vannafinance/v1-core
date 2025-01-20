// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
interface IPTrackToken is IERC20 {
    function mint() external;
}
