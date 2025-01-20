pragma solidity ^0.8.17;

import {ERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TrackToken is ERC20 {

    constructor() ERC20("TrackToken","TToken") public {}
    
        function mint(address account) public returns (uint256){
            if(balanceOf(account) == 0) {
                _mint(account, 1 ether);
            }
            return balanceOf(account); 

    }
}