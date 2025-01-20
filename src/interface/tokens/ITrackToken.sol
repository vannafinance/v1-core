// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "./IERC20.sol";
interface ITrackToken is IERC20 {
    function mint(address account) external;
}
