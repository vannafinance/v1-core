// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "./IERC20.sol";
import {IERC4626} from "./IERC4626.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {IOwnable} from "../utils/IOwnable.sol";
import {IRegistry} from "../core/IRegistry.sol";
import {IRateModel} from "../core/IRateModel.sol";

interface IVToken {
    function init(
        ERC20 _asset,
        string calldata _name,
        string calldata _symbol,
        IRegistry _registry,
        uint _originationFee,
        address treasury,
        uint _min_mint,
        uint _maxSupply
    ) external;

    function initDep(string calldata) external;

    function registry() external returns (IRegistry);
    function rateModel() external returns (IRateModel);
    function accountManager() external returns (address);

    function updateState() external;
    function lendTo(address account, uint amt) external returns (bool);
    function collectFrom(address account, uint amt) external returns (bool);

    function getBorrows() external view returns (uint);
    function getBorrowBalance(address account) external view returns (uint);
}