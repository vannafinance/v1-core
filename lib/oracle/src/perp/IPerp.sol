// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct OpenPositionParams {
        address baseToken;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint256 deadline;
        uint160 sqrtPriceLimitX96;
        bytes32 referralCode;
}
interface IPerp__{
    function openPosition(OpenPositionParams memory params) external; 
    function getAccountValue(address trader) external view returns (int256);
}