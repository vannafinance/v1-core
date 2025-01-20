pragma solidity ^0.8.17;
// Interface for the WETH contract
interface IWETH {
    function deposit() external payable; // Wrap ETH to WETH
    function transfer(address to, uint256 value) external returns (bool);
}


