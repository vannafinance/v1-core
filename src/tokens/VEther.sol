// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {VToken} from "./VToken.sol";
import {Errors} from "../utils/Errors.sol";
import {Helpers} from "../utils/Helpers.sol";
import {ERC20} from "../../lib/solmate/src/tokens/ERC20.sol";

interface IWETH {
    function withdraw(uint) external;
    function deposit() external payable;
}

/**
    @title Lending Token for Ether
    @notice Lending Token contract for Ether with WETH as underlying asset
*/
contract VEther is VToken {
    using Helpers for address;

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Wraps Eth sent by the user and deposits into the LP
            Transfers shares to the user denoting the amount of Eth deposited
        @dev Emits Deposit(caller, owner, assets, shares)
    */
    function depositEth() external payable returns (uint shares) {
        uint assets = msg.value;

        beforeDeposit(assets, shares);
        if ((shares = previewDeposit(assets)) == 0) revert Errors.ZeroShares();

        IWETH(address(asset)).deposit{value: assets}();

        _mint(msg.sender, shares);
        emit Deposit(msg.sender, msg.sender, assets, shares);
    }

    /**
        @notice Unwraps Eth and transfers it to the caller
            Amount of Eth transferred will be the total underlying assets that
            are represented by the shares
        @dev Emits Withdraw(caller, receiver, owner, assets, shares);
        @param shares Amount of shares to redeem
    */
    function redeemEth(uint shares) external returns (uint assets) {
        if ((assets = previewRedeem(shares)) == 0) revert Errors.ZeroAssets();
        beforeWithdraw(assets, shares);

        _burn(msg.sender, shares);
        emit Withdraw(msg.sender, msg.sender, msg.sender, assets, shares);

        IWETH(address(asset)).withdraw(assets);
        msg.sender.safeTransferEth(assets);
    }

    receive() external payable {}
}