// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IPTToken} from "./IPTToken.sol";
import {IOracle} from "../core/IOracle.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {WETHOracle} from "../weth/WETHOracle.sol";
import {console2} from "lib/forge-std/src/console2.sol";
import {IPerp__,OpenPositionParams} from "./IPerp.sol";
import {AggregatorV3Interface} from "../chainlink/AggregatorV3Interface.sol";
import {Errors} from "../utils/Errors.sol";
/**
    @title IPerp TToken Oracle
    @notice Oracle for fetching price for TToken
*/

contract PTTokenOracle is IOracle {
    using Math for uint256;
    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Oracle Facade
    IOracle public immutable oracle;
     /// @notice ETH USD Chainlink price feed
    AggregatorV3Interface immutable ethUsdPriceFeed;

    /// @notice L2 Sequencer feed
    AggregatorV3Interface immutable sequencer;

    /// @notice L2 Sequencer grace period
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    IPerp__ perphouse = IPerp__(0x82ac2CE43e33683c58BE4cDc40975E73aA50f459);

    address WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // IMulticall public immutable Multicall;

    // ITradingStorage public immutable TradingStorage;



    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */
  


    /*
        @notice Contract constructor
        @param _oracle Oracle Facade Address
    */
    constructor(IOracle _oracle,AggregatorV3Interface _ethFeed, AggregatorV3Interface _sequencer) {
        oracle = _oracle;
        ethUsdPriceFeed = _ethFeed;
        sequencer = _sequencer;

       
    }


    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */
    function isSequencerActive() internal view returns (bool) {
        (, int256 answer, uint256 startedAt,,) = sequencer.latestRoundData();
        if (block.timestamp - startedAt <= GRACE_PERIOD_TIME || answer == 1) {
            return false;
        }
        return true;
    }

    function getEthPrice() internal view returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = ethUsdPriceFeed.latestRoundData();

        if (block.timestamp - updatedAt >= 86400) {
            revert Errors.StalePrice(address(0), address(ethUsdPriceFeed));
        }
        if (answer <= 0) {
            revert Errors.NegativePrice(address(0), address(ethUsdPriceFeed));
        }
        return uint256(answer);
    }
    
    function getPrice(address token,address account) external view override returns (uint price) {
        if (!isSequencerActive()) revert Errors.L2SequencerUnavailable();
        price = uint(perphouse.getAccountValue(account));
        return uint(price * 1e8)/ getEthPrice();
    }
}