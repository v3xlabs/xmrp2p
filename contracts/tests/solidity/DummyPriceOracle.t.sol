// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AggregatorV3Interface} from "../../main/solidity/AggregatorV3Interface.sol";

contract DummyPriceOracle is AggregatorV3Interface {

    uint8 private DECIMALS;
    uint80 private ROUNDID;
    int256 private ANSWER;
    uint256 private STARTEDAT;
    uint256 private UPDATEDAT;
    uint80 private ANSWEREDINROUND;

    constructor(
        uint8 dec,
        int256 answer,
        uint256 updatedAt
    ) {
        DECIMALS = dec;
        ROUNDID = 0;
        ANSWER = answer;
        STARTEDAT = 0;
        UPDATEDAT = updatedAt;
        ANSWEREDINROUND = 0;
    }

    function decimals() external view returns (uint8) {
        return DECIMALS;
    }
    
    function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        return (ROUNDID,ANSWER,STARTEDAT,UPDATEDAT,ANSWEREDINROUND);
    }
}