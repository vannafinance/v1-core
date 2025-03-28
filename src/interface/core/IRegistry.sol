// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRegistry {
    event AccountCreated(address indexed account, address indexed owner);

    function init() external;

    function addressFor(string calldata id) external view returns (address);
    function ownerFor(address account) external view returns (address);

    function getAllVTokens() external view returns (address[] memory);
    function VTokenFor(address underlying) external view returns (address);

    function setAddress(string calldata id, address _address) external;
    function setVToken(address underlying, address vToken) external;

    function addAccount(address account, address owner) external;
    function updateAccount(address account, address owner) external;
    function closeAccount(address account) external;

    function getAllAccounts() external view returns(address[] memory);
    function accountsOwnedBy(address user)
        external view returns (address[] memory);
    function getAddress(string calldata) external view returns (address);
    function accounts(uint i) external view returns (address);
}