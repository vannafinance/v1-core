// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IVToken} from "./IVToken.sol";

interface IVEther is IVToken {
    function depositEth() external payable returns (uint);
    function redeemEth(uint shares) external returns (uint);
}