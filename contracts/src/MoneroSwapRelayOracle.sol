// SPDX-License-Identifier: MIT
//
// Copyright (c) 2025-2026  hbs
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

pragma solidity ^0.8.34;

import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";

contract MoneroSwapRelayOracle is AggregatorV3Interface {

    uint8 private DECIMALS = 18;
    uint64 private CHAINID = 0;
    address private SOURCE = address(0);
    uint80 private ROUNDID = 0;
    // This is the adjusted answer (see RATE below)
    int256 private ANSWER = 0;
    uint256 private STARTEDAT = 0;
    uint256 private UPDATEDAT = 0;
    uint80 private ANSWEREDINROUND = 0;
    // This is an additional rate used to compute the exposed price.
    // For example when relaying feeds which server XMR-USD on Gnosis Chain
    // we must adjust the answer by the DAI-USD rate to serve an XMR-DAI rate.
    // RATE is meant to expose the rate used.
    uint256 private RATE = 0;

    address private owner;

    constructor(address ownerAddress) {
        require(address(0) != ownerAddress);
        owner = ownerAddress;
    }

    function setOwner(address ownerAddress) public {
        require(msg.sender == owner);
        require(address(0) != ownerAddress);
        owner = ownerAddress;
    }
    
    function decimals() external view returns (uint8) {
        return DECIMALS;
    }

    function update(
        uint64 chainid,
        address source,
        uint80 roundid,
        int256 answer,
        uint256 startedat,
        uint256 updatedat,
        uint80 answeredinround,
        uint256 rate) public {

        // Sender must be the current owner    
        require(msg.sender == owner);
        // Timestamp updatedat cannot go back in time
        // It could be identical to the previously relayed value IFF RATE has
        // changed but we are still relaying the same oracle round
        require(updatedat >= UPDATEDAT);
        // Either source or chainid differ, roundid cannot decrease (as for updatedat, it could
        // be identical when just updating RATE)
        require(chainid != CHAINID || source != SOURCE || roundid >= ROUNDID);

        CHAINID = chainid;
        SOURCE = source;
        ROUNDID = roundid;
        ANSWER = answer;
        STARTEDAT = startedat;
        UPDATEDAT = updatedat;
        ANSWEREDINROUND = answeredinround;
        RATE = rate;
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

    function latestRoundDataExtended()
    external
    view
    returns (
      uint64 chainid,
      address source,
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound,
      uint256 rate
    ) {
        return (CHAINID,SOURCE,ROUNDID,ANSWER,STARTEDAT,UPDATEDAT,ANSWEREDINROUND,RATE);
    }
}