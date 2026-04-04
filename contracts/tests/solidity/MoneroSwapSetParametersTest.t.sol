// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {XMRP2P} from "../../src/XMRP2P.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import "../../src/Errors.sol";
import "../../src/Errors.sol";

import {Utils} from "./Utils.t.sol";

contract MoneroSwapSetParametersTest is Test {
    function test_RevertWhen_DelayTooShort() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 delay = vm.randomUint() % Utils.MINIMUM_DELAY;

        vm.expectRevert(abi.encodeWithSelector(ErrorDelayTooShort.selector, delay, Utils.MINIMUM_DELAY));
        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            1, // MinimumBuyOffer,
            1000 ether, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            1, // MaximumSellOffer,
            1, // SellOfferCoverageRatio,
            delay, // T0Delay,
            Utils.MINIMUM_DELAY + 1 // T1Delay
        );

        vm.expectRevert(abi.encodeWithSelector(ErrorDelayTooShort.selector, delay, Utils.MINIMUM_DELAY));
        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            1, // MinimumBuyOffer,
            1000 ether, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            1, // MaximumSellOffer,
            1, // SellOfferCoverageRatio,
            Utils.MINIMUM_DELAY, // T0Delay,
            delay // T1Delay
        );
    }

    function testSetParameters() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 FundingRequestMaxBalance = vm.randomUint();
        uint256 FundingRequestMinFeeRatio = vm.randomUint();
        uint256 MaximumBuyOfferBookSize = vm.randomUint();
        uint256 MinimumBuyOffer = vm.randomUint();
        uint256 MaximumBuyOffer = vm.randomUint();
        uint256 MaximumSellOfferBookSize = vm.randomUint();
        uint256 MinimumSellOffer = vm.randomUint();
        uint256 MaximumSellOffer = vm.randomUint();
        uint256 SellOfferCoverageRatio = vm.randomUint();
        uint256 T0Delay = Utils.MINIMUM_DELAY + vm.randomUint();
        uint256 T1Delay = Utils.MINIMUM_DELAY + vm.randomUint();

        // Set the parameters
        vm.prank(msg.sender);
        moneroswap.setParameters(
            FundingRequestMaxBalance,
            FundingRequestMinFeeRatio,
            MaximumBuyOfferBookSize,
            MinimumBuyOffer,
            MaximumBuyOffer,
            MaximumSellOfferBookSize,
            MinimumSellOffer,
            MaximumSellOffer,
            SellOfferCoverageRatio,
            T0Delay,
            T1Delay
        );

        MoneroSwap.Parameters memory parameters = moneroswap.getParameters();

        assertEq(FundingRequestMaxBalance, parameters.FUNDING_REQUEST_MAXBALANCE);
        assertEq(FundingRequestMinFeeRatio, parameters.FUNDING_REQUEST_MIN_FEE_RATIO);
        assertEq(MaximumBuyOfferBookSize, parameters.MAXIMUM_BUY_OFFER_BOOK_SIZE);
        assertEq(MinimumBuyOffer, parameters.MINIMUM_BUY_OFFER);
        assertEq(MaximumBuyOffer, parameters.MAXIMUM_BUY_OFFER);
        assertEq(MaximumSellOfferBookSize, parameters.MAXIMUM_SELL_OFFER_BOOK_SIZE);
        assertEq(MinimumSellOffer, parameters.MINIMUM_SELL_OFFER);
        assertEq(MaximumSellOffer, parameters.MAXIMUM_SELL_OFFER);
        assertEq(SellOfferCoverageRatio, parameters.SELL_OFFER_COVERAGE_RATIO);
        assertEq(T0Delay, parameters.T0_DELAY);
        assertEq(T1Delay, parameters.T1_DELAY);
    }
}
