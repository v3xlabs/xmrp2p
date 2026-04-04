// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import "../../src/Errors.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";

import {Utils} from "./Utils.t.sol";
import {EIP7702NoPaymentDelegate} from "./EIP7702NoPaymentDelegate.t.sol";

contract MoneroSwapClaimTest is Test {

    uint256 KEY_BASE = 1000000;

    address ADDR_1;
    uint256 PK_1;
    address ADDR_2;
    uint256 PK_2;
    address ADDR_3;
    uint256 PK_3;

    function setUp() public {
        // Generate deterministic keys

        (ADDR_1, PK_1) = makeAddrAndKey("user-1");
        (ADDR_2, PK_2) = makeAddrAndKey("user-2");
        (ADDR_3, PK_3) = makeAddrAndKey("user-3");
    }

    function test_RevertWhen_BuyOfferInvalidState() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            KEY_BASE++ // msg pub key
        );

        // Check when offer is in state OPEN
        vm.expectRevert(abi.encodeWithSelector(
            ErrorBuyOfferInvalidStateForClaim.selector,
            OfferState.OPEN
        ));
        moneroswap.claim(1, 0);
    }

    function test_RevertWhen_BuyOfferAfterT1() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            KEY_BASE++ // msg pub key
        );

        // Take and ready the offer
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000,
            1 ether,
            KEY_BASE++,
            KEY_BASE++,
            1
        );
        moneroswap.ready(1);
        Offer memory offer = moneroswap.getBuyOffer(1);
        vm.warp(offer.t1 + 1);
        // Check when offer is in state READY
        vm.expectRevert(abi.encodeWithSelector(
            ErrorBuyOfferAfterT1.selector
        ));
        moneroswap.claim(1, 0);
    }

    function test_RevertWhen_BuyOfferNotBetweenT0AndT1() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            KEY_BASE++ // msg pub key
        );

        // Take the offer
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000,
            1 ether,
            KEY_BASE++,
            KEY_BASE++,
            1
        );
        Offer memory offer = moneroswap.getBuyOffer(1);

        // Check at t0
        vm.warp(offer.t0);
        vm.expectRevert(abi.encodeWithSelector(
            ErrorBuyOfferNotBetweenT0AndT1.selector
        ));
        moneroswap.claim(1, 0);

        // Check at t1 + 1
        vm.warp(offer.t1 + 1);
        vm.expectRevert(abi.encodeWithSelector(
            ErrorBuyOfferNotBetweenT0AndT1.selector
        ));
        moneroswap.claim(1, 0);
    }

    function test_RevertWhen_BuyOfferNotTaker() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            KEY_BASE++ // msg pub key
        );

        // Take and ready the offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000,
            1 ether,
            KEY_BASE++,
            KEY_BASE++,
            1
        );
        moneroswap.ready(1);

        // Attempt to claim from the wrong account
        vm.prank(ADDR_2);
        vm.expectRevert(abi.encodeWithSelector(
            ErrorBuyOfferNotTaker.selector
        ));
        moneroswap.claim(1, 0);
    }

    function test_RevertWhen_BuyOfferInvalidXMRPrivateSpendKey() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            KEY_BASE++ // msg pub key
        );

        // Take and ready the offer
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000,
            1 ether,
            KEY_BASE++,
            KEY_BASE++,
            1
        );
        moneroswap.ready(1);

        vm.expectRevert(abi.encodeWithSelector(
            ErrorBuyOfferInvalidXMRPrivateSpendKey.selector
        ));
        moneroswap.claim(1, 0);        
    }

    function test_RevertWhen_SellOfferInvalidState() public {        
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        moneroswap.createSellOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            1_000_000_000_000, // max XMR
            KEY_BASE++, // public spend key
            KEY_BASE++, // private view key
            KEY_BASE++ // msg pub key
        );

        vm.expectRevert(abi.encodeWithSelector(
            ErrorSellOfferInvalidStateForClaim.selector,
            OfferState.OPEN
        ));
        moneroswap.claim(1, 0);        
    }

    function test_RevertWhen_SellOfferAfterT1() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        moneroswap.createSellOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            1_000_000_000_000, // max XMR
            KEY_BASE++, // public spend key
            KEY_BASE++, // private view key
            KEY_BASE++ // msg pub key
        );

        // Take and ready the offer
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000,
            1 ether,
            KEY_BASE++,
            KEY_BASE++,
            1
        );
        moneroswap.ready(1);

        vm.warp(moneroswap.getSellOffer(1).t1 + 1);
        vm.expectRevert(abi.encodeWithSelector(
            ErrorSellOfferAfterT1.selector
        ));
        moneroswap.claim(1, 0);        
    }

    function test_RevertWhen_SellOfferNotOwner() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        moneroswap.createSellOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            1_000_000_000_000, // max XMR
            KEY_BASE++, // public spend key
            KEY_BASE++, // private view key
            KEY_BASE++ // msg pub key
        );

        // Take and ready the offer
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000,
            1 ether,
            KEY_BASE++,
            KEY_BASE++,
            1
        );
        moneroswap.ready(1);

        vm.prank(ADDR_2);
        vm.expectRevert(abi.encodeWithSelector(
            ErrorSellOfferNotOwner.selector
        ));
        moneroswap.claim(1, 0);        
    }

    function test_RevertWhen_SellOfferNotBetweenT0AndT1() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        moneroswap.createSellOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            1_000_000_000_000, // max XMR
            KEY_BASE++, // public spend key
            KEY_BASE++, // private view key
            KEY_BASE++ // msg pub key
        );

        // Take and ready the offer
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000,
            1 ether,
            KEY_BASE++,
            KEY_BASE++,
            1
        );

        vm.warp(moneroswap.getSellOffer(1).t1 + 1);
        vm.expectRevert(abi.encodeWithSelector(
            ErrorSellOfferNotBetweenT0AndT1.selector
        ));
        moneroswap.claim(1, 0);

        vm.warp(moneroswap.getSellOffer(1).t0);
        vm.expectRevert(abi.encodeWithSelector(
            ErrorSellOfferNotBetweenT0AndT1.selector
        ));
        moneroswap.claim(1, 0);       
    }

    function test_RevertWhen_SellOfferInvalidXMRPrivateSpendKey() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        moneroswap.createSellOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            1_000_000_000_000, // max XMR
            KEY_BASE++, // public spend key
            KEY_BASE++, // private view key
            KEY_BASE++ // msg pub key
        );

        // Take and ready the offer
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000,
            1 ether,
            KEY_BASE++,
            KEY_BASE++,
            1
        );
        moneroswap.ready(1);

        vm.expectRevert(abi.encodeWithSelector(
            ErrorSellOfferInvalidXMRPrivateSpendKey.selector
        ));
        moneroswap.claim(1, 0);        
    }

    function test_RevertWhen_InvalidOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.expectRevert(abi.encodeWithSelector(
            ErrorInvalidOffer.selector
        ));
        moneroswap.claim(1, 0);        
    }

    function testClaimBuyOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            evmPublicSpendKey, // public spend key
            evmPublicViewKey, // public view key
            0 // msg pub key
        );

        // Take and ready the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        assertEq(2 ether, moneroswap.getLiability());

        vm.prank(ADDR_1);
        moneroswap.ready(1);

        vm.deal(ADDR_2, 0);
        vm.prank(ADDR_2);
        moneroswap.claim(1, xmrPrivateSpendKey);        
        // taker should have received the swap amount + its deposit
        assertEq(2 ether, ADDR_2.balance);
        // Contract has no liability
        assertEq(0, moneroswap.getLiability());

    }

    function testClaimBuyOfferFunded() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 2 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 2 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            evmPublicSpendKey, // public spend key
            evmPublicViewKey, // public view key
            0 // msg pub key
        );

        // Check that deposit is 2 ether
        Offer memory offer = moneroswap.getBuyOffer(1);
        assertEq(2 ether, offer.deposit);

        // Create a funding request
        vm.prank(ADDR_2);
        uint256 fee = 1 + (vm.randomUint() % 0.1 ether);
        moneroswap.createFundingRequest(1 ether, fee);

        // Fund the funding request
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_2);

        // Liability is 3 ether, 2 ether of buy offer owner's deposit, and 1 ether of funder deposit
        assertEq(3 ether, moneroswap.getLiability());

        // Take and ready the offer
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 0}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        // Check that the delta between actual swap amount and the deposit was returned to the buyer
        assertEq(1 ether, ((address(ADDR_1)).balance));
        // Check that the deposit has been updated
        offer = moneroswap.getBuyOffer(1);
        assertEq(1 ether, offer.deposit);

        // liability has changed because the taker only bought 1 ether worth of XMR, so 1 ether was returned to the buyer already
        assertEq(2 ether, moneroswap.getLiability());
    
        vm.prank(ADDR_1);
        moneroswap.ready(1);

        vm.deal(ADDR_2, 0);
        vm.prank(ADDR_2);
        moneroswap.claim(1, xmrPrivateSpendKey);        
        // taker should have received the swap amount minus the fee
        assertEq(1 ether - fee, ADDR_2.balance);
        // Funder should have receive the fee plus the funding amount
        assertEq(1 ether + fee, ADDR_3.balance);
        // Buy Offer owner should have received the difference between the deposit and the settled amount
        assertEq(1 ether, ADDR_1.balance);
        // Contract has no liability
        assertEq(0, moneroswap.getLiability());
        // FundingRequest should have disappeared
        vm.expectRevert(ErrorFundingRequestNotFound.selector);
        moneroswap.getFundingRequest(ADDR_2);
    }
    
    function testClaimSellOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey, // private view key
            0 // msg pub key
        );

        // Take and ready the offer
        vm.deal(ADDR_2, 2 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 2 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // privateviewkey
            0                  // msgpubkey
        );

        assertEq(2 ether, moneroswap.getLiability());

        vm.prank(ADDR_2);
        moneroswap.ready(1);

        vm.deal(ADDR_1, 0);
        vm.prank(ADDR_1);
        moneroswap.claim(1, xmrPrivateSpendKey);        
        // taker should have received the swap amount + its deposit
        assertEq(2 ether, ADDR_1.balance);
        assertEq(0, moneroswap.getLiability());
    }

    function testClaimSellOfferFunded() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        uint256 fee = 1 + (vm.randomUint() % 0.1 ether);
        // Create a funding request
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, fee);

        // Fund the funding request
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        assertEq(1 ether, moneroswap.getLiability());

        // Create a sell offer
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey, // private view key
            0 // msg pub key
        );

        // Liability has not changed since the sell offer is funded
        assertEq(1 ether, moneroswap.getLiability());
        
        // Take and ready the offer
        vm.deal(ADDR_2, 2 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 2 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // privateviewkey
            0                  // msgpubkey
        );

        // Liability is 2 ether, 1 from the funding of the FundingRequest,
        // the other from the sell offer counterparty (the extra amount has already been sent back)
        assertEq(2 ether, moneroswap.getLiability());

        vm.prank(ADDR_2);
        moneroswap.ready(1);

        vm.deal(ADDR_1, 0);
        vm.prank(ADDR_1);
        moneroswap.claim(1, xmrPrivateSpendKey);        
        // taker should have received the swap amount minus the fee
        assertEq(1 ether - fee, ADDR_1.balance);
        // Funder should have receive the fee plus the funding amount
        assertEq(1 ether + fee, ADDR_3.balance);
        // Buyer should have received 0 on top of its current balance of 1 ether
        assertEq(1 ether, ADDR_2.balance);
        // Contract has no liability
        assertEq(0, moneroswap.getLiability());

    }

    function testClaimBuyOffer_RevertWhen_SellerEIP7702Delegation() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            evmPublicSpendKey, // public spend key
            evmPublicViewKey, // public view key
            0 // msg pub key
        );

        // Take and ready the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        assertEq(2 ether, moneroswap.getLiability());

        vm.prank(ADDR_1);
        moneroswap.ready(1);

        // Attach a Delegation on seller
        vm.signAndAttachDelegation(address(new EIP7702NoPaymentDelegate()), PK_2);

        vm.deal(ADDR_2, 0);
        vm.prank(ADDR_2);
        vm.expectRevert(ErrorUnableToPayClaimer.selector);
        moneroswap.claim(1, xmrPrivateSpendKey);
        vm.signAndAttachDelegation(address(0), PK_2);        
    }

    function testClaimSellOffer_RevertWhen_SellerEIP7702Delegation() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey, // private view key
            0 // msg pub key
        );

        // Take and ready the offer
        vm.deal(ADDR_2, 2 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 2 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // privateviewkey
            0                  // msgpubkey
        );

        assertEq(2 ether, moneroswap.getLiability());

        vm.prank(ADDR_2);
        moneroswap.ready(1);

        // Attach a Delegation on seller
        vm.signAndAttachDelegation(address(new EIP7702NoPaymentDelegate()), PK_1);

        vm.deal(ADDR_1, 0);
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorUnableToPayClaimer.selector);
        moneroswap.claim(1, xmrPrivateSpendKey);  

        vm.signAndAttachDelegation(address(0), PK_1);      
    }

    function testClaimBuyOfferFundedWithFunderEIP7702Delegation() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 2 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 2 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            evmPublicSpendKey, // public spend key
            evmPublicViewKey, // public view key
            0 // msg pub key
        );

        // Check that deposit is 2 ether
        Offer memory offer = moneroswap.getBuyOffer(1);
        assertEq(2 ether, offer.deposit);

        // Create a funding request
        vm.prank(ADDR_2);
        uint256 fee = 1 + (vm.randomUint() % 0.1 ether);
        moneroswap.createFundingRequest(1 ether, fee);

        // Fund the funding request
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_2);

        // Liability is 3 ether, 2 ether of buy offer owner's deposit, and 1 ether of funder deposit
        assertEq(3 ether, moneroswap.getLiability());

        // Take and ready the offer
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 0}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        // Check that the delta between actual swap amount and the deposit was returned to the buyer
        assertEq(1 ether, ((address(ADDR_1)).balance));
        // Check that the deposit has been updated
        offer = moneroswap.getBuyOffer(1);
        assertEq(1 ether, offer.deposit);

        // liability has changed because the taker only bought 1 ether worth of XMR, so 1 ether was returned to the buyer already
        assertEq(2 ether, moneroswap.getLiability());
    
        vm.prank(ADDR_1);
        moneroswap.ready(1);

        // Attach a Delegation on funder
        vm.signAndAttachDelegation(address(new EIP7702NoPaymentDelegate()), PK_3);

        vm.deal(ADDR_2, 0);
        vm.prank(ADDR_2);
        moneroswap.claim(1, xmrPrivateSpendKey);        
        // taker should have received the swap amount minus the fee
        assertEq(1 ether - fee, ADDR_2.balance);
        // Funder should have received nothing since it has an EIP7702 delegation which rejects payments
        assertEq(0, ADDR_3.balance);
        // Buy Offer owner should have received the difference between the deposit and the settled amount
        assertEq(1 ether, ADDR_1.balance);
        // Contract has the principal + fee of the funder as liability
        assertEq(1 ether + fee, moneroswap.getLiability());
        // FundingRequest should still be there and unchanged
        FundingRequest memory freq = moneroswap.getFundingRequest(ADDR_2);
        assertEq(fee, freq.fee);
        assertEq(1 ether, freq.amount);
        assertEq(1, freq.usedby);
        vm.signAndAttachDelegation(address(0), PK_3);
    }

    function testClaimSellOfferFundedWithFunderEIP7702Delegation() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        uint256 fee = 1 + (vm.randomUint() % 0.1 ether);
        // Create a funding request
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, fee);

        // Fund the funding request
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        assertEq(1 ether, moneroswap.getLiability());

        // Create a sell offer
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey, // private view key
            0 // msg pub key
        );

        // Liability has not changed since the sell offer is funded
        assertEq(1 ether, moneroswap.getLiability());
        
        // Take and ready the offer
        vm.deal(ADDR_2, 2 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 2 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // privateviewkey
            0                  // msgpubkey
        );

        // Liability is 2 ether, 1 from the funding of the FundingRequest,
        // the other from the sell offer counterparty (the extra amount has already been sent back)
        assertEq(2 ether, moneroswap.getLiability());

        vm.prank(ADDR_2);
        moneroswap.ready(1);

        // Attach a Delegation on funder
        vm.signAndAttachDelegation(address(new EIP7702NoPaymentDelegate()), PK_3);

        vm.deal(ADDR_1, 0);
        vm.prank(ADDR_1);
        moneroswap.claim(1, xmrPrivateSpendKey);        
        // taker should have received the swap amount minus the fee
        assertEq(1 ether - fee, ADDR_1.balance);
        // Funder should have received nothing since its EIP7702 delegate refuses payments
        assertEq(0, ADDR_3.balance);
        // Buyer should have received 0 on top of its current balance of 1 ether
        assertEq(1 ether, ADDR_2.balance);
        // Contract has funder's principal + fee as liability
        assertEq(1 ether + fee, moneroswap.getLiability());

        // FundingRequest should still be there and unchanged
        FundingRequest memory freq = moneroswap.getFundingRequest(ADDR_1);
        assertEq(fee, freq.fee);
        assertEq(1 ether, freq.amount);
        assertEq(1, freq.usedby);
        vm.signAndAttachDelegation(address(0), PK_3);
    }
}