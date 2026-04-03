// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../main/solidity/MoneroSwap.sol";
import {Utils} from "./Utils.t.sol";
import {EIP7702NoPaymentDelegate} from "./EIP7702NoPaymentDelegate.t.sol";

/// Tests related to FundingRequest
contract MoneroSwapClaimFundingRequestTest is Test {

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

    function test_RevertWhen_RequestNotInUse() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a FundingRequest
        vm.deal(ADDR_1, 1 ether - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        // Fund the funding request
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        // Attempt to claim the FundingRequest
        vm.prank(ADDR_2);
        vm.expectRevert(MoneroSwap.ErrorFundingRequestNotInUse.selector);
        moneroswap.claimFundingRequest(ADDR_1);
    }

    function test_RevertWhen_NotFunderOrFundee() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a FundingRequest
        vm.deal(ADDR_1, 1 ether - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        // Fund the funding request
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        vm.prank(ADDR_3);
        vm.expectRevert(MoneroSwap.ErrorFundingRequestClaimableOnlyByFunderOrFundee.selector);
        moneroswap.claimFundingRequest(ADDR_1);
    }

    function test_RevertWhen_NotClaimableTakenButBeforeT0() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 amount = 1 ether + (vm.randomUint() % (0.5 ether));
        uint256 fee = 1 + vm.randomUint() % (amount / 2);

        // Create a FundingRequest
        vm.deal(ADDR_1, amount - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(amount, fee);

        // Fund the funding request
        vm.deal(ADDR_2, amount * 2);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: amount}(ADDR_1);

        // Create a sell offer
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
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0), // counterparty
            ADDR_1, // manager
            amount, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            amount, // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey, // private view key
            0 // msg pub key
        );

        // Take sell offer
        (
            evmPrivateViewKey,
            evmPrivateSpendKey,
            evmPublicViewKey,
            evmPublicSpendKey,
            xmrPrivateViewKey,
            xmrPrivateSpendKey,
            xmrPublicViewKey,
            xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        vm.deal(ADDR_3, amount * 2);
        vm.prank(ADDR_3);
        moneroswap.takeSellOffer{value: amount}(1, 1_000_000_000_000, amount, evmPublicSpendKey, evmPublicViewKey, 0);
        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);

        // Attemtp to claim the FundingRequest. The timestamp is too early (before t0)
        vm.prank(ADDR_2);
        vm.warp(offer.t0);        
        vm.expectRevert(MoneroSwap.ErrorFundingRequestNotClaimable.selector);
        moneroswap.claimFundingRequest(ADDR_1);

        // Now claim it after t0
        vm.warp(offer.t0 + 1);
        uint256 balance = address(ADDR_2).balance;
        uint256 liability = moneroswap.getLiability();
        vm.prank(ADDR_2);
        moneroswap.claimFundingRequest(ADDR_1);
        assertEq(balance + amount, address(ADDR_2).balance);
        assertEq(moneroswap.getLiability(), liability - amount);
    }

    function test_claimFundingRequest() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 amount = 1 ether + (vm.randomUint() % (0.5 ether));
        uint256 fee = 1 + vm.randomUint() % (amount / 2);

        // Create a FundingRequest
        vm.deal(ADDR_1, amount - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(amount, fee);

        // Fund the funding request
        vm.deal(ADDR_2, amount * 2);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: amount}(ADDR_1);

        // Create a sell offer
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
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0), // counterparty
            ADDR_1, // manager
            amount, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            amount, // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey, // private view key
            0 // msg pub key
        );

        // Take sell offer
        (
            evmPrivateViewKey,
            evmPrivateSpendKey,
            evmPublicViewKey,
            evmPublicSpendKey,
            xmrPrivateViewKey,
            xmrPrivateSpendKey,
            xmrPublicViewKey,
            xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        vm.deal(ADDR_3, amount * 2);
        vm.prank(ADDR_3);
        moneroswap.takeSellOffer{value: amount}(1, 1_000_000_000_000, amount, evmPublicSpendKey, evmPublicViewKey, 0);

        // Ready the offer
        vm.prank(ADDR_3);
        moneroswap.ready(1);

        uint256 balance = address(ADDR_2).balance;
        uint256 liability = moneroswap.getLiability();
        vm.prank(ADDR_2);
        moneroswap.claimFundingRequest(ADDR_1);

        assertEq(balance + amount, address(ADDR_2).balance);
        assertEq(moneroswap.getLiability(), liability - amount);

        // Check that the funding request has now an amount set to 0
        MoneroSwap.FundingRequest memory freq = moneroswap.getFundingRequest(ADDR_1);
        assertEq(freq.amount, 0);
    }

    function test_claimFundingRequestWhenFunderEIP7702DelegationDuringClaim() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 amount = 1 ether + (vm.randomUint() % (0.5 ether));
        uint256 fee = 1 + vm.randomUint() % (amount / 2);

        // Create a FundingRequest
        vm.deal(ADDR_1, amount - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(amount, fee);

        // Fund the funding request
        vm.deal(ADDR_2, amount * 2);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: amount}(ADDR_1);

        // Create a sell offer
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
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0), // counterparty
            ADDR_1, // manager
            amount, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            amount, // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey, // private view key
            0 // msg pub key
        );

        uint256 xmrPrivateSpendKey1 = xmrPrivateSpendKey;

        // Take sell offer
        (
            evmPrivateViewKey,
            evmPrivateSpendKey,
            evmPublicViewKey,
            evmPublicSpendKey,
            xmrPrivateViewKey,
            xmrPrivateSpendKey,
            xmrPublicViewKey,
            xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        vm.deal(ADDR_3, amount * 2);
        vm.prank(ADDR_3);
        moneroswap.takeSellOffer{value: amount}(1, 1_000_000_000_000, amount, evmPublicSpendKey, evmPublicViewKey, 0);

        // Ready the offer
        vm.prank(ADDR_3);
        moneroswap.ready(1);

        // Attach a Delegation on seller
        vm.signAndAttachDelegation(address(new EIP7702NoPaymentDelegate()), PK_2);

        uint256 balance = address(ADDR_2).balance;
        uint256 liability = moneroswap.getLiability();

        // Claim the offer (since the funder has an EIP7702 delegation which rejects payments, the claim won't pay principal or fee)
        vm.prank(ADDR_1);
        moneroswap.claim(1, xmrPrivateSpendKey1); 

        // Balance of funder hasn't changed
        assertEq(balance, address(ADDR_2).balance);
        // Liability hasn't changed
        assertEq(liability - amount + fee, moneroswap.getLiability());

        // Now claim the Funding Request without the EIP7702
        vm.signAndAttachDelegation(address(0), PK_2);
        balance = address(ADDR_2).balance;
        liability = moneroswap.getLiability();
        vm.prank(ADDR_2);
        moneroswap.claimFundingRequest(ADDR_1);

        assertEq(balance + amount + fee, address(ADDR_2).balance);
        assertEq(liability - amount - fee, moneroswap.getLiability());

        // Check that the funding request no longer exists
        vm.expectRevert(MoneroSwap.ErrorFundingRequestNotFound.selector);
        MoneroSwap.FundingRequest memory freq = moneroswap.getFundingRequest(ADDR_1);
    }
}