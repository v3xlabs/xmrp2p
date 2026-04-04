// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import "../../src/Errors.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";

import {Utils} from "./Utils.t.sol";

contract MoneroSwapTakeBuyOfferTest is Test {

    uint256 KEY_BASE = 100000000000000000000000;

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);
    address ADDR_3 = address(0x3333333333333333333333333333333333333333);
    
    uint256 constant RATIO_DENOMINATOR = 1_000_000_000;
    uint256 constant UNITS_PER_XMR = 1_000_000_000_000;

    function test_RevertWhen_BuyOfferUnknown() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Attempt to take a non existent buy offer
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferUnknown.selector);
        moneroswap.takeBuyOffer(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1,                 // minprice
            KEY_BASE + 1,      // publicspendkey
            KEY_BASE + 2      // privateviewkey
        );
    }

    function test_RevertWhen_BuyOfferNotOpen() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            1_000_000_000_000, // min XMR
            KEY_BASE + 3,      // public spend key
            KEY_BASE + 4      // public view key
        );

        // Take the offer so it is no longer takeable
        vm.deal(ADDR_2, 2 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1,                 // minprice
            KEY_BASE + 5,      // publicspendkey
            KEY_BASE + 6      // privateviewkey
        );

        // Attempt to retake the offer
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferInvalidStateForTake.selector,
                OfferState.TAKEN
            )
        );
        moneroswap.takeBuyOffer(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1,                 // minprice
            KEY_BASE + 7,      // publicspendkey
            KEY_BASE + 8      // privateviewkey
        );
    }

    function test_RevertWhen_NoValueAndNoFundingRequest() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            1_000_000_000_000, // min XMR
            KEY_BASE + 9,      // public spend key
            KEY_BASE + 10     // public view key
        );

        // Attempt to take the offer without a value and without a funding request
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferNoFundingRequestFound.selector
            )
        );
        moneroswap.takeBuyOffer(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1,                 // minprice
            KEY_BASE + 11,     // publicspendkey
            KEY_BASE + 12     // privateviewkey
        );
    }

    function test_RevertWhen_NoValueAndFundingRequestNotFunded() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            1_000_000_000_000, // min XMR
            KEY_BASE + 13,     // public spend key
            KEY_BASE + 14     // public view key
        );

        // Create a funding request
        vm.prank(ADDR_2);
        moneroswap.createFundingRequest(
            1 ether,           // amount
            0                  // fee
        );

        // Attempt to take the offer without a value and without a funded funding request
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorFundingRequestNotFunded.selector
            )
        );
        moneroswap.takeBuyOffer(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1,                 // minprice
            KEY_BASE + 15,     // publicspendkey
            KEY_BASE + 16     // privateviewkey
        );
    }

    function test_RevertWhen_NoValueAndFundingRequestAlreadyInUse() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            1_000_000_000_000, // min XMR
            KEY_BASE + 17,     // public spend key
            KEY_BASE + 18     // public view key
        );

        // Create a funding request
        vm.prank(ADDR_2);
        moneroswap.createFundingRequest(
            1 ether,           // amount
            0                  // fee
        );

        // Fund the funding request
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_2);

        // Take the offer. This will use the FundingRequest
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 0}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1,                 // minprice
            KEY_BASE + 19,     // publicspendkey
            KEY_BASE + 20     // privateviewkey
        );

        // Create another buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            1_000_000_000_000, // min XMR
            KEY_BASE + 21,     // public spend key
            KEY_BASE + 22     // public view key
        );

        // Attempt to take the offer, as the funding request is already used with will fail
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorFundingRequestAlreadyInUse.selector
            )
        );
        moneroswap.takeBuyOffer{value: 0}(
            2,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1,                 // minprice
            KEY_BASE + 23,     // publicspendkey
            KEY_BASE + 24     // privateviewkey
        );
    } 

    /// @notice Test that a takeBuyOffer reverts when the taker has an available unused FundingRequest
    function test_RevertWhen_FundingRequestAvailable() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            1_000_000_000_000, // min XMR
            KEY_BASE + 25,     // public spend key
            KEY_BASE + 26     // public view key
        );

        // Create a funding request - It doesn't have to be funded
        vm.prank(ADDR_2);
        moneroswap.createFundingRequest(
            1 ether,           // amount
            0                  // fee
        );

        // Attempt to take the offer with a non 0 value, as the taker has an available unused FundingRequest this should fail
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferAvailableFundingRequest.selector
            )
        );
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1,                 // minprice
            KEY_BASE + 27,     // publicspendkey
            KEY_BASE + 28     // privateviewkey
        );
    }

    function test_RevertWhen_XMRAmountTooLow() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            UNITS_PER_XMR,     // min XMR
            KEY_BASE + 29,     // public spend key
            KEY_BASE + 30     // public view key
        );

        // Attempt to take the offer with a value too low
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferXMRAmountTooLow.selector,
                UNITS_PER_XMR - 1,
                UNITS_PER_XMR
            )
        );
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR - 1, // maxxmr
            1,                 // minprice
            KEY_BASE + 31,     // publicspendkey
            KEY_BASE + 32     // privateviewkey
        );
    }

    function test_RevertWhen_PublicSpendKeyAlreadyUsed() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            UNITS_PER_XMR,     // min XMR
            KEY_BASE + 33,     // public spend key
            KEY_BASE + 34     // public view key
        );

        // Attempt to take the offer with a value too low
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferPublicSpendKeyAlreadyUsed.selector
            )
        );
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1,                 // minprice
            KEY_BASE + 33,     // publicspendkey
            KEY_BASE + 34     // privateviewkey
        );
    }

    /// @notice Test that a takeBuyOffer reverts when the computed final swap price is below the minimum price set by the taker
    function test_RevertWhen_PriceTooLow() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            UNITS_PER_XMR,     // min XMR
            KEY_BASE + 37,     // public spend key
            KEY_BASE + 38     // public view key
        );

        // Attempt to take the offer with a price too high
        vm.deal(ADDR_2, 10 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferPriceTooLow.selector,
                1 ether, // Computed swap price
                2 ether  // minprice
            )
        );
        moneroswap.takeBuyOffer{value: 4 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            2 ether,           // minprice
            KEY_BASE + 39,     // publicspendkey
            KEY_BASE + 40     // privateviewkey
        );
    }

    /// Test the case when the computed XMR amount (based on the deposit/funding) is too low
    function test_RevertWhen_XMRAmountTooLowDueToDeposit() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            UNITS_PER_XMR,     // min XMR
            KEY_BASE + 45,     // public spend key
            KEY_BASE + 46     // public view key
        );

        // Attempt to take the offer with a deposit which will only provide 0.5 XMR at the offer price
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferXMRAmountTooLow.selector,
                UNITS_PER_XMR / 2,
                UNITS_PER_XMR
            )
        );
        moneroswap.takeBuyOffer{value: 0.5 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1 ether,           // minprice
            KEY_BASE + 47,     // publicspendkey
            KEY_BASE + 48     // privateviewkey
        );
    }

    function test_RevertWhen_AmountTooLowToCoverFundingFee() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            UNITS_PER_XMR,     // min XMR
            KEY_BASE + 49,     // public spend key
            KEY_BASE + 50     // public view key
        );

        // Create a funding request with a fee above the buy offer amount
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.createFundingRequest(
            100 ether,         // amount
            2 ether            // fee
        );

        // Fund the FundingRequest
        vm.deal(ADDR_3, 200 ether);
        vm.prank(ADDR_3);
        moneroswap.fundFundingRequest{value: 100 ether}(ADDR_2);

        // Attempt to take the offer with a deposit which will only provide 0.5 XMR at the offer price
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferAmountTooLowToCoverFundingFee.selector
            )
        );

        moneroswap.takeBuyOffer{value: 0}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1 ether,           // minprice
            KEY_BASE + 51,     // publicspendkey
            KEY_BASE + 52     // privateviewkey
        );
    }

    function test_RevertWhen_InvalidCounterparty() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(ADDR_3),   // counterparty
            1 ether,           // fixed price
            UNITS_PER_XMR,     // min XMR
            KEY_BASE + 53,     // public spend key
            KEY_BASE + 54     // public view key
        );

        // Attempt to take the offer from an EOA which is not the specified counterparty
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferInvalidCounterparty.selector
            )
        );
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1 ether,           // minprice
            KEY_BASE + 55,     // publicspendkey
            KEY_BASE + 56     // privateviewkey
        );
    }

    function test_RevertWhen_UsedPublicSpendKey() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        // Create a buy offer with keys 1/2/3
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            1_000_000_000_000, // min XMR
            1,                 // public spend key
            2                 // public view key
        );

        // Attempt to take offer with pub spend key 2 (used public view key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferPublicSpendKeyAlreadyUsed.selector
            )
        );
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1 ether,           // minprice
            2,                 // publicspendkey
            4                 // privateviewkey
        );

        // Attempt to create another offer with pub spend key 3 (used public message key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferPublicSpendKeyAlreadyUsed.selector
            )
        );
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1 ether,           // minprice
            3,                 // publicspendkey
            6                 // privateviewkey
        );
    }
    function testTakeBuyOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            UNITS_PER_XMR,     // min XMR
            KEY_BASE + 57,     // public spend key
            KEY_BASE + 58     // public view key
        );

        uint256 liability = moneroswap.getLiability();
        assertEq(liability, 1 ether);

        // Take the offer
        uint256 xmrDeposit = 1 ether + (vm.randomUint() % 1 ether);
        vm.deal(ADDR_2, xmrDeposit);    
        vm.prank(ADDR_2);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(
            1,                 // offer id
            OfferType.BUY,
            OfferState.TAKEN
        );
        moneroswap.takeBuyOffer{value: xmrDeposit}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1 ether,           // minprice
            KEY_BASE + 59,     // publicspendkey
            KEY_BASE + 60     // privateviewkey
        );

        assertEq(moneroswap.getLiability(), 1 ether + xmrDeposit);
        
        MoneroSwap.Parameters memory PARAMETERS = moneroswap.getParameters();

        // Retrieve the offer
        Offer memory offer = moneroswap.getBuyOffer(1);
        assert(offer.state == OfferState.TAKEN);
        assertEq(offer.counterparty, ADDR_2);
        assertEq(offer.blockTaken, block.number);
        assertEq(offer.lastupdate, block.timestamp);
        assertEq(offer.takerDeposit, xmrDeposit);
        assertEq(offer.xmrPublicSpendKey, KEY_BASE + 59);
        assertEq(offer.xmrPrivateViewKey, KEY_BASE + 60);
        assertEq(offer.finalprice, 1 ether);
        assertEq(offer.finalxmr, UNITS_PER_XMR);
        assertEq(offer.t0, block.timestamp + PARAMETERS.T0_DELAY);
        assertEq(offer.t1, offer.t0 + PARAMETERS.T1_DELAY);

        assertEq(moneroswap.getLiability(), liability + xmrDeposit);
    }

    function testTakeBuyOfferWithFundingRequest() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            UNITS_PER_XMR,     // min XMR
            KEY_BASE + 61,     // public spend key
            KEY_BASE + 62     // public view key
        );

        uint256 liability = moneroswap.getLiability();
        assertEq(liability, 1 ether);


        // Take the offer
        uint256 xmrDeposit = 1 ether + (vm.randomUint() % 1 ether);

        // Create a funding request 
        vm.deal(ADDR_2, xmrDeposit - 1);    
        vm.prank(ADDR_2);
        moneroswap.createFundingRequest(
            xmrDeposit,        // amount
            0.1 ether          // fee
        );

        // Fund the FundingRequest
        vm.deal(ADDR_3, 200 ether);
        vm.prank(ADDR_3);
        moneroswap.fundFundingRequest{value: xmrDeposit}(ADDR_2);

        // Take the offer
        vm.prank(ADDR_2);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(
            1,                 // offer id
            OfferType.BUY,
            OfferState.TAKEN
        );
        moneroswap.takeBuyOffer{value: 0}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1 ether,           // minprice
            KEY_BASE + 63,     // publicspendkey
            KEY_BASE + 64     // privateviewkey
        );

        assertEq(moneroswap.getLiability(), 1 ether + xmrDeposit);
        
        MoneroSwap.Parameters memory PARAMETERS = moneroswap.getParameters();

        // Retrieve the offer
        Offer memory offer = moneroswap.getBuyOffer(1);
        assert(offer.state == OfferState.TAKEN);
        assertEq(offer.counterparty, ADDR_2);
        assertEq(offer.blockTaken, block.number);
        assertEq(offer.lastupdate, block.timestamp);
        assertEq(offer.takerDeposit, 0);
        assertEq(offer.xmrPublicSpendKey, KEY_BASE + 63);
        assertEq(offer.xmrPrivateViewKey, KEY_BASE + 64);
        assertEq(offer.finalprice, 1 ether);
        assertEq(offer.finalxmr, UNITS_PER_XMR);
        assertEq(offer.t0, block.timestamp + PARAMETERS.T0_DELAY);
        assertEq(offer.t1, offer.t0 + PARAMETERS.T1_DELAY);

        assertEq(moneroswap.getLiability(), liability + xmrDeposit);

        FundingRequest memory freq = moneroswap.getFundingRequest(ADDR_2);
        assertEq(freq.amount, xmrDeposit);
        assertEq(freq.fee, 0.1 ether);
        assertEq(freq.usedby, 1);
    }

}
