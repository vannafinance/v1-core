// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IController} from "../core/IController.sol";
import {IPTrackToken} from "./IPTrackToken.sol";


/**
    @title Perp Vault Controller
    @notice Controller for Interacting with Perp orderManager for openposition.
*/
contract Perp1Controller is IController {

    /* -------------------------------------------------------------------------- */
    /*                             CONSTANT VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice placeOrder(uint8 _updateType,uint8 _side,address _indexToken,address _collateralToken,uint8 _orderType,bytes data) function signature
    bytes4 constant openPosition = 0xb6b1b6c3;
    bytes4 constant closePosition = 0x00aa9a89;
    bytes4 constant deposit = 0x47e7ef24;
    bytes4 constant withdraw = 0xf3fef3a3;
     bytes4 constant withdrawAll = 0xfa09e630;


    address public immutable PTrackToken;

    /// @notice List of tokens
    /// @dev Will always have one token WETH
    address public USDC;


    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    constructor(
        address _pTrackToken,
        address usdc
    ) {
        PTrackToken = _pTrackToken;
        USDC = usdc;
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */



    /// @inheritdoc IController
    function canCall(address target, bool, bytes calldata data)
        external
        view
        returns (bool, address[] memory, address[] memory)
    {
        bytes4 sig = bytes4(data);

        if (sig == openPosition || sig == deposit) {
            address[] memory tokensIn = new address[](1);
            
            address[] memory tokensOut = new address[](1);

            
            tokensIn[0] = USDC;
            tokensOut[0] = PTrackToken;

            return (true, tokensIn, tokensOut);
        }
        else if (sig == closePosition || sig == withdraw || sig == withdrawAll){
            address[] memory tokensIn = new address[](1);
            
            address[] memory tokensOut = new address[](1);

            
            tokensIn[0] = PTrackToken;
            tokensOut[0] = USDC;

            return (true, tokensIn, tokensOut);

        }
    
        return (false, new address[](0), new address[](0));
    }
}