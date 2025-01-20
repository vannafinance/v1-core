// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";

/**
    @title Registry Contract
    @notice This contract stores:
        1. Address of all accounts as well their owners
        2. Active VToken addresses and Token->VToken mapping
        3. Address of all deployed protocol contracts
*/
contract Registry is Ownable, IRegistry{
    /* -------------------------------------------------------------------------- */
    /*                              STATE VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Utility variable to indicate if contract is initialized
    bool private initialized;

    /// @notice List of contracts
    /// @dev Contract Name should be separated by _ and in all caps Ex. (REGISTRY, RATE_MODEL)
    string[] public keys;

    /// @notice List of accounts
    address[] public accounts;

    /// @notice List of active vTokens
    address[] public vTokens;

    /// @notice Account address to owner mapping (account => owner)
    mapping(address => address) public ownerFor;

    /// @notice Token to VToken mapping (token => VToken)
    mapping (address => address) public VTokenFor;

    /// @notice Contract name to contract address mapping (contractName => contract)
    mapping(string => address) public addressFor;

    /* -------------------------------------------------------------------------- */
    /*                              CUSTOM MODIFIERS                              */
    /* -------------------------------------------------------------------------- */

    modifier accountManagerOnly() {
        if (msg.sender != addressFor["ACCOUNT_MANAGER"])
            revert Errors.AccountManagerOnly();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract Initialization function
        @dev Can only be invoked once
    */
    function init() external {
        if (initialized) revert Errors.ContractAlreadyInitialized();
        initialized = true;
        initOwnable(msg.sender);
    }

    /**
        @notice Sets contract address for a given contract id
        @dev If address is 0x0 it removes the address from keys.
        If addressFor[id] returns 0x0 then the contract id is added to keys
        @param id Contract name, format (REGISTRY, RATE_MODEL)
        @param _address Address of the contract
    */
    function setAddress(
        string calldata id,
        address _address
    ) external adminOnly {
        if (addressFor[id] == address(0)) {
            if (_address == address(0)) revert Errors.ZeroAddress();
            keys.push(id);
        } else if (_address == address(0)) removeKey(id);

        addressFor[id] = _address;
    }

    /**
        @notice Sets VToken address for a specified token
        @dev If underlying token is 0x0 VToken is removed from vTokens
        if the mapping doesn't exist VToken is pushed to vTokens
        if the mapping exist VToken is updated in vTokens
        @param underlying Address of token
        @param vToken Address of VToken
    */
    function setVToken(address underlying, address vToken) external adminOnly {
        if (VTokenFor[underlying] == address(0)) {
            if (vToken == address(0)) revert Errors.ZeroAddress();
            vTokens.push(vToken);
        } else if (vToken == address(0)) removeVToken(VTokenFor[underlying]);
        else updateVToken(VTokenFor[underlying], vToken);

        VTokenFor[underlying] = vToken;
    }

    /**
        @notice Adds account and sets owner of the account
        @dev Adds account to accounts and stores owner for the account.
        Event AccountCreated(account, owner) is emitted
        @param account Address of account
        @param owner Address of owner of the account
    */
    function addAccount(
        address account,
        address owner
    ) external accountManagerOnly {
        ownerFor[account] = owner;
        accounts.push(account);
        emit AccountCreated(account, owner);
    }

    /**
        @notice Updates owner of account
        @param account Address of account
        @param owner Address of owner of account
    */
    function updateAccount(
        address account,
        address owner
    ) external accountManagerOnly {
        ownerFor[account] = owner;
    }

    /**
        @notice Closes account
        @dev Sets address of owner for the account to 0x0
        @param account Address of account to close
    */
    function closeAccount(address account) external accountManagerOnly {
        ownerFor[account] = address(0);
    }

    /* -------------------------------------------------------------------------- */
    /*                               VIEW FUNCTIONS                               */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Returns all contract names in registry
        @return keys List of contract names
    */
    function getAllKeys() external view returns (string[] memory) {
        return keys;
    }

    /**
        @notice Returns all accounts in registry
        @return accounts List of accounts
    */
    function getAllAccounts() external view returns (address[] memory) {
        return accounts;
    }

    /**
        @notice Returns all active VTokens in registry
        @return vTokens List of vTokens
    */
    function getAllVTokens() external view returns (address[] memory) {
        return vTokens;
    }

    /**
        @notice Returns all accounts owned by a specific user
        @param user Address of user
        @return userAccounts List of accounts
    */
    function accountsOwnedBy(
        address user
    ) external view returns (address[] memory userAccounts) {
        userAccounts = new address[](accounts.length);
        uint index;
        for (uint i; i < accounts.length; i++) {
            if (ownerFor[accounts[i]] == user) {
                userAccounts[index] = accounts[i];
                index++;
            }
        }
        assembly {
            mstore(userAccounts, index)
        }
    }

    /**
        @notice Returns address of a specified contract deployed by the protocol
        @dev Reverts if there is no contract deployed
        @param id Name of the contract, Eg: ACCOUNT_MANAGER
        @return value Address of deployed contract
    */
    function getAddress(
        string calldata id
    ) external view returns (address value) {
        if ((value = addressFor[id]) == address(0)) revert Errors.ZeroAddress();
    }

    /* -------------------------------------------------------------------------- */
    /*                              HELPER FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    function updateVToken(address vToken, address newVToken) internal {
        uint len = vTokens.length;
        for (uint i; i < len; ++i) {
            if (vTokens[i] == vToken) {
                vTokens[i] = newVToken;
                break;
            }
        }
    }

    function removeVToken(address underlying) internal {
        uint len = vTokens.length;
        for (uint i; i < len; ++i) {
            if (underlying == vTokens[i]) {
                vTokens[i] = vTokens[len - 1];
                vTokens.pop();
                break;
            }
        }
    }

    function removeKey(string calldata id) internal {
        uint len = keys.length;
        bytes32 keyHash = keccak256(abi.encodePacked(id));
        for (uint i; i < len; ++i) {
            if (keyHash == keccak256(abi.encodePacked((keys[i])))) {
                keys[i] = keys[len - 1];
                keys.pop();
                break;
            }
        }
    }
}