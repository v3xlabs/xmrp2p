// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {MoneroSwap} from "../../main/solidity/MoneroSwap.sol";
import {AggregatorV3Interface} from "../../main/solidity/AggregatorV3Interface.sol";
import {DummyPriceOracle} from "./DummyPriceOracle.t.sol";

contract MoneroSwapGetXMRPriceTest is Test {

    function test_RevertWhen_NoOracleDefined() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorBuyOfferNoPriceOracleDefined.selector
            )
        );
        moneroswap.getXMRPrice(
            MoneroSwap.OfferType.BUY,
            0, // price
            1, // ratio
            2, // offset
            3 // minprice
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferNoPriceOracleDefined.selector
            )
        );
        moneroswap.getXMRPrice(
            MoneroSwap.OfferType.SELL,
            0, // price
            1, // ratio
            2, // offset
            3 // maxprice
        );
    }

    function test_RevertWhen_OraclePriceTooOld() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        AggregatorV3Interface oracle = new DummyPriceOracle(8, 100, block.timestamp - 1000);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorBuyOfferOraclePriceTooOld.selector
            )
        );
        moneroswap.getXMRPrice(
            MoneroSwap.OfferType.BUY,
            0, // price
            1, // ratio
            2, // offset
            3 // minprice
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferOraclePriceTooOld.selector
            )
        );
        moneroswap.getXMRPrice(
            MoneroSwap.OfferType.SELL,
            0, // price
            1, // ratio
            2, // offset
            3 // maxprice
        );
    }

    function test_RevertWhen_PriceTooLow() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        AggregatorV3Interface oracle = new DummyPriceOracle(8, 100, block.timestamp);

        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorBuyOfferPriceTooLow.selector,
                2, // Offer price
                3  // Min price
            )
        );
        moneroswap.getXMRPrice(
            MoneroSwap.OfferType.BUY,
            2, // price
            0, // ratio
            0, // offset
            3 // minprice
        );

        // Now set an oracle
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorBuyOfferPriceTooLow.selector,
                1_000_000_000_002, // Offer price
                1_000_000_000_003  // Min price
            )
        );

        moneroswap.getXMRPrice(
            MoneroSwap.OfferType.BUY,
            5, // price - we use a non 0 value to check that it is not considered when ratio is not 0
            1_000_000_000, // ratio
            2, // offset
            1_000_000_000_003 // minprice
        );
    }

    function test_RevertWhen_PriceTooHigh() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        AggregatorV3Interface oracle = new DummyPriceOracle(8, 100, block.timestamp);

        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferPriceTooHigh.selector,
                2, // Offer price
                1  // Max price
            )
        );
        moneroswap.getXMRPrice(
            MoneroSwap.OfferType.SELL,
            2, // price
            0, // ratio
            0, // offset
            1 // maxprice
        );

        // Now set an oracle
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferPriceTooHigh.selector,
                1_000_000_000_002, // Offer price
                1_000_000_000_001  // Max price
            )
        );

        moneroswap.getXMRPrice(
            MoneroSwap.OfferType.SELL,
            5, // price - we use a non 0 value to check that it is not considered when ratio is not 0
            1_000_000_000, // ratio
            2, // offset
            1_000_000_000_001 // maxprice
        );
    }
    
    function testOraclePrice() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        AggregatorV3Interface oracle = new DummyPriceOracle(8, 100, block.timestamp);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        assertEq(moneroswap.getXMRPrice(
            MoneroSwap.OfferType.BUY,
            0, // price
            1_000_000_000, // ratio
            2, // offset
            0 // minprice
        ), 1_000_000_000_002); // 10^10 * 100 + 2 - with 10^10 being 10^(18 - 8)

        assertEq(moneroswap.getXMRPrice(
            MoneroSwap.OfferType.SELL,
            0, // price
            1_000_000_000, // ratio
            2, // offset
            1_000_000_000_002 // maxprice
        ), 1_000_000_000_002); // 10^10 * 100 + 2 - with 10^10 being 10^(18 - 8)
    }

    function test_RevertWhen_InvalidOfferType() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorInvalidOfferType.selector
            )
        );

        moneroswap.getXMRPrice(
            MoneroSwap.OfferType.INVALID,
            0, // price
            0, // ratio
            0, // offset
            0 // maxprice
        );
    }
}