// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IOracle} from "lib/oracle/src/core/IOracle.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";
import {IVToken} from "../interface/tokens/IVToken.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {IRiskEngine} from "../interface/core/IRiskEngine.sol";
import {IAccountManager} from "../interface/core/IAccountManager.sol";
import {FixedPointMathLib} from "lib/solmate/src/utils/FixedPointMathLib.sol";
import {console} from "lib/forge-std/src/console.sol";

/**
    @title Risk Engine
    @notice Risk engine is a vanna utility contract used by the protocol to
    analyze the health factor of a given account.
*/
contract RiskEngine is Ownable, IRiskEngine {
    using FixedPointMathLib for uint;

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Registry
    IRegistry public immutable registry;

    /// @notice Oracle Facade
    IOracle public oracle;

    /// @notice Account Manager
    IAccountManager public accountManager;

    /// @notice Balance:Borrow, Default = 1.2
    uint public constant balanceToBorrowThreshold = 1.1e18;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract constructor
        @param _registry Address of registry contract
    */
    constructor(IRegistry _registry) {
        initOwnable(msg.sender);
        registry = _registry;
    }

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Initializes external dependencies
    function initDep() external adminOnly {
        oracle = IOracle(registry.getAddress('ORACLE'));
        accountManager = IAccountManager(registry.getAddress('ACCOUNT_MANAGER'));
    }

    /**
        @notice Utility function to determine if an account can borrow a
        specified amount of a token
            isBorrowAllowed = (currentAccountBalance + borrowValue) /
                (currentAccountBorrows + borrowValue) > balanceToBorrowThreshold
        @param account Address of account
        @param token Address of token
        @param amt Amount of token to borrow
        @return isBorrowAllowed Returns whether a borrow is allowed or not
    */
    function isBorrowAllowed(
        address account,
        address token,
        uint amt
    )
        external
        returns (bool)
    {
        uint borrowValue = _valueInWei(token, amt,account);
        return _isAccountHealthy(
            _getBalance(account) + borrowValue,
            _getBorrows(account) + borrowValue
        );
    }

    /**
        @notice Utility function to determine if an account can withdraw a
        specified amount of a token
            isWithdrawAllowed = (currentAccountBalance - withdrawValue) /
                currentAccountBorrows > balanceToBorrowThreshold
        @param account Address of account
        @param token Address of token
        @param amt Amount of token to withdraw
        @return isWithdrawAllowed Returns whether a withdraw is allowed or not
    */
    function isWithdrawAllowed(
        address account,
        address token,
        uint amt
    )
        external
        returns (bool)
    {
        if (IAccount(account).hasNoDebt()) return true;
        return _isAccountHealthy(
            _getBalance(account) - _valueInWei(token, amt,account),
            _getBorrows(account)
        );
    }

    /**
        @notice Utility function to determine if an account is healthy or not
            isAccountHealthy = currentAccountBalance / currentAccountBorrows >
                balanceToBorrowThreshold
         @param account Address of account
        @return isAccountHealthy Returns whether an account is healthy or not.
    */
    function isAccountHealthy(address account) external returns (bool) {
        return _isAccountHealthy(
            _getBalance(account),
            _getBorrows(account)
        );
    }
    

    /**
        @notice Returns total account Balance
        @param account Address of account
        @return balance Total account balance
    */
    function getBalance(address account) external returns (uint) {
        return _getBalance(account);
    }

    /**
        @notice Returns total account Borrows
        @param account Address of account
        @return borrows Total account borrows
    */
    function getBorrows(address account) external returns (uint) {
        return _getBorrows(account);
    }

    /* -------------------------------------------------------------------------- */
    /*                             Internal Functions                             */
    /* -------------------------------------------------------------------------- */

    function _getBalance(address account) internal returns (uint) {
        address[] memory assets = IAccount(account).getAssets();
        uint assetsLen = assets.length;
        uint totalBalance;
        for(uint i; i < assetsLen; ++i) {
            totalBalance += _valueInWei(
                assets[i],
                IERC20(assets[i]).balanceOf(account),
                account
            );
        }
        return totalBalance + account.balance;
    }

    function _getBorrows(address account) internal returns (uint) {
        if (IAccount(account).hasNoDebt()) return 0;
        address[] memory borrows = IAccount(account).getBorrows();
        uint borrowsLen = borrows.length;
        uint totalBorrows;
        for(uint i; i < borrowsLen; ++i) {
            address VTokenAddr = registry.VTokenFor(borrows[i]);
            totalBorrows += _valueInWei(
                borrows[i],
                IVToken(VTokenAddr).getBorrowBalance(account),
                account
            );
        }
        return totalBorrows;
    }

    function _valueInWei(address token, uint amt,address account)
        internal
        returns (uint)
    {   
        return oracle.getPrice(token,account)
        .mulDivDown(
            amt,
            10 ** ((token == address(0)) ? 18 : IERC20(token).decimals())
        );
    }

    function _isAccountHealthy(uint accountBalance, uint accountBorrows)
        internal
        pure
        returns (bool)
    {
        return (accountBorrows == 0) ? true :
            (accountBalance.divWadDown(accountBorrows) > balanceToBorrowThreshold);
    }
}