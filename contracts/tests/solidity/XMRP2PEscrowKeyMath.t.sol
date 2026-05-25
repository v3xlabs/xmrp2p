// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Ed25519} from "../../src/Ed25519.sol";
import {OfferState, OfferType} from "../../src/Enums.sol";
import {XMRP2P} from "../../src/XMRP2P.sol";
import {XMRP2PTestBase} from "./XMRP2PTestBase.t.sol";

contract XMRP2PEscrowKeyMathTest is XMRP2PTestBase {
    uint256 internal constant ED25519_L = 2 ** 252 + 27742317777372353535851937790883648493;

    uint256 internal constant EVM_PRIVATE_SPEND_KEY =
        0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20;
    uint256 internal constant EVM_PRIVATE_VIEW_KEY =
        0x002122232425262728292a2b2c2d2e2f06733e75ee45fc8a8814740682519665;
    uint256 internal constant XMR_PRIVATE_SPEND_KEY =
        0x00000305070b0d1113171d1f25292b2f353b3d43474b4d53596165676b6d717f;
    uint256 internal constant XMR_PRIVATE_VIEW_KEY =
        0x00050b11171d23292f353b41474d53595f656b71777d83898f959ba1a7adb3b9;

    uint256 internal constant EVM_PUBLIC_SPEND_KEY =
        0x80334024b705b5fd76b1bce1b26d96234ab7b2d989987895fa72c43b3e5c5f85;
    uint256 internal constant EVM_PUBLIC_VIEW_KEY =
        0x8c7484063283269ee01b559071699006a8cbc0da555dcd8e146e95fc85fad86f;
    uint256 internal constant XMR_PUBLIC_SPEND_KEY =
        0xf2ea39797d89a5eeef6db0c4f67ffe0a6451da4a9ff823fc3cbcdc7f2993131f;
    uint256 internal constant XMR_PUBLIC_VIEW_KEY =
        0x0db8334bea0959aa830413ed782da42e7dc67c1b6f8dbb2ab6323c448020d583;

    uint256 internal constant ESCROW_PRIVATE_SPEND_KEY =
        0x010206090c1114191c21282b32373a3f464d50575c61646b727b8083888b909f;
    uint256 internal constant ESCROW_PRIVATE_VIEW_KEY =
        0x00262d343b424950575e656c737a818865d8a9e765c3801417aa0fa829ff4a1e;
    uint256 internal constant ESCROW_PUBLIC_SPEND_KEY =
        0x3b24bd214751109170f3de9ad3ecb37e7a2b5cdec361a7a6f2b064ddb78bc8f4;
    uint256 internal constant ESCROW_PUBLIC_VIEW_KEY =
        0x584ac7b7d4edfd403e9387140f6923a67df1d863757390f3170ad653e484d1bb;
    string internal constant ESCROW_MAINNET_ADDRESS =
        "43s6tyuD9VyRKxoH3LQsxnN9zGyJtRp9kUvc5SHeJCmDhsTBvNm6r1rBkFb9Zbg2N6UrBUoqk5YgFhfH6qBEm7egN818HaZ";

    function testFixedEscrowKeyMathVectors() public view {
        assertLt(EVM_PRIVATE_SPEND_KEY, ED25519_L);
        assertLt(EVM_PRIVATE_VIEW_KEY, ED25519_L);
        assertLt(XMR_PRIVATE_SPEND_KEY, ED25519_L);
        assertLt(XMR_PRIVATE_VIEW_KEY, ED25519_L);

        assertEq(_combinePrivateKeys(EVM_PRIVATE_SPEND_KEY, XMR_PRIVATE_SPEND_KEY), ESCROW_PRIVATE_SPEND_KEY);
        assertEq(_combinePrivateKeys(EVM_PRIVATE_VIEW_KEY, XMR_PRIVATE_VIEW_KEY), ESCROW_PRIVATE_VIEW_KEY);

        assertEq(_publicKey(EVM_PRIVATE_SPEND_KEY), EVM_PUBLIC_SPEND_KEY);
        assertEq(_publicKey(EVM_PRIVATE_VIEW_KEY), EVM_PUBLIC_VIEW_KEY);
        assertEq(_publicKey(XMR_PRIVATE_SPEND_KEY), XMR_PUBLIC_SPEND_KEY);
        assertEq(_publicKey(XMR_PRIVATE_VIEW_KEY), XMR_PUBLIC_VIEW_KEY);

        assertEq(_publicKey(ESCROW_PRIVATE_SPEND_KEY), ESCROW_PUBLIC_SPEND_KEY);
        assertEq(_publicKey(ESCROW_PRIVATE_VIEW_KEY), ESCROW_PUBLIC_VIEW_KEY);

        assertEq(
            ESCROW_MAINNET_ADDRESS,
            "43s6tyuD9VyRKxoH3LQsxnN9zGyJtRp9kUvc5SHeJCmDhsTBvNm6r1rBkFb9Zbg2N6UrBUoqk5YgFhfH6qBEm7egN818HaZ"
        );
    }

    function testBuyClaimRevealsXmrShareSoBuyerCanRecoverEscrowKeys() public {
        uint256 offerId = _openAndTakeBuyOffer();

        vm.prank(buyer);
        exchange.ready(offerId);

        vm.prank(seller);
        exchange.claim(offerId, XMR_PRIVATE_SPEND_KEY);

        XMRP2P.Offer memory offer = _offerSnapshot(offerId);
        assertEq(uint256(offer.state), uint256(OfferState.CLAIMED));
        assertEq(offer.xmrPrivateSpendKey, XMR_PRIVATE_SPEND_KEY);

        uint256 recoveredSpendKey = _combinePrivateKeys(EVM_PRIVATE_SPEND_KEY, offer.xmrPrivateSpendKey);
        uint256 recoveredViewKey = _combinePrivateKeys(EVM_PRIVATE_VIEW_KEY, offer.xmrPrivateViewKey);
        _assertRecoveredEscrowKeys(recoveredSpendKey, recoveredViewKey);
    }

    function testBuyRefundRevealsEvmShareSoSellerCanRecoverEscrowKeys() public {
        uint256 offerId = _openAndTakeBuyOffer();

        vm.prank(buyer);
        exchange.quit(offerId, EVM_PRIVATE_SPEND_KEY, EVM_PRIVATE_VIEW_KEY);

        XMRP2P.Offer memory offer = _offerSnapshot(offerId);
        assertEq(uint256(offer.state), uint256(OfferState.REFUNDED));
        assertEq(offer.evmPrivateSpendKey, EVM_PRIVATE_SPEND_KEY);
        assertEq(offer.evmPrivateViewKey, EVM_PRIVATE_VIEW_KEY);

        uint256 recoveredSpendKey = _combinePrivateKeys(offer.evmPrivateSpendKey, XMR_PRIVATE_SPEND_KEY);
        uint256 recoveredViewKey = _combinePrivateKeys(offer.evmPrivateViewKey, XMR_PRIVATE_VIEW_KEY);
        _assertRecoveredEscrowKeys(recoveredSpendKey, recoveredViewKey);
    }

    function testSellClaimRevealsXmrShareSoBuyerCanRecoverEscrowKeys() public {
        uint256 offerId = _openAndTakeSellOffer();

        vm.prank(buyer);
        exchange.ready(offerId);

        vm.prank(seller);
        exchange.claim(offerId, XMR_PRIVATE_SPEND_KEY);

        XMRP2P.Offer memory offer = _offerSnapshot(offerId);
        assertEq(uint256(offer.state), uint256(OfferState.CLAIMED));
        assertEq(offer.xmrPrivateSpendKey, XMR_PRIVATE_SPEND_KEY);

        uint256 recoveredSpendKey = _combinePrivateKeys(EVM_PRIVATE_SPEND_KEY, offer.xmrPrivateSpendKey);
        uint256 recoveredViewKey = _combinePrivateKeys(EVM_PRIVATE_VIEW_KEY, offer.xmrPrivateViewKey);
        _assertRecoveredEscrowKeys(recoveredSpendKey, recoveredViewKey);
    }

    function testSellRefundRevealsEvmShareSoSellerCanRecoverEscrowKeys() public {
        uint256 offerId = _openAndTakeSellOffer();

        vm.roll(block.number + 1);
        vm.prank(buyer);
        exchange.quit(offerId, EVM_PRIVATE_SPEND_KEY, EVM_PRIVATE_VIEW_KEY);

        XMRP2P.Offer memory offer = _offerSnapshot(offerId);
        assertEq(uint256(offer.state), uint256(OfferState.REFUNDED));
        assertEq(offer.evmPrivateSpendKey, EVM_PRIVATE_SPEND_KEY);
        assertEq(offer.evmPrivateViewKey, EVM_PRIVATE_VIEW_KEY);

        uint256 recoveredSpendKey = _combinePrivateKeys(offer.evmPrivateSpendKey, XMR_PRIVATE_SPEND_KEY);
        uint256 recoveredViewKey = _combinePrivateKeys(offer.evmPrivateViewKey, XMR_PRIVATE_VIEW_KEY);
        _assertRecoveredEscrowKeys(recoveredSpendKey, recoveredViewKey);
    }

    function _openAndTakeBuyOffer() internal returns (uint256 offerId) {
        vm.prank(buyer);
        exchange.openOffer{value: TRADE_AMOUNT}(
            OfferType.BUY, XMR_AMOUNT, address(0), EVM_PUBLIC_SPEND_KEY, EVM_PUBLIC_VIEW_KEY
        );
        offerId = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offerId, XMR_PUBLIC_SPEND_KEY, XMR_PRIVATE_VIEW_KEY);

        XMRP2P.Offer memory offer = _offerSnapshot(offerId);
        assertEq(offer.evmPublicSpendKey, EVM_PUBLIC_SPEND_KEY);
        assertEq(offer.evmPublicViewKey, EVM_PUBLIC_VIEW_KEY);
        assertEq(offer.xmrPublicSpendKey, XMR_PUBLIC_SPEND_KEY);
        assertEq(offer.xmrPrivateViewKey, XMR_PRIVATE_VIEW_KEY);
    }

    function _openAndTakeSellOffer() internal returns (uint256 offerId) {
        vm.prank(seller);
        exchange.openOffer{value: REQUIRED_DEPOSIT}(
            OfferType.SELL, XMR_AMOUNT, address(0), XMR_PUBLIC_SPEND_KEY, XMR_PRIVATE_VIEW_KEY
        );
        offerId = exchange.nextOfferId() - 1;

        vm.prank(buyer);
        exchange.take{value: TRADE_AMOUNT}(offerId, EVM_PUBLIC_SPEND_KEY, EVM_PUBLIC_VIEW_KEY);

        XMRP2P.Offer memory offer = _offerSnapshot(offerId);
        assertEq(offer.evmPublicSpendKey, EVM_PUBLIC_SPEND_KEY);
        assertEq(offer.evmPublicViewKey, EVM_PUBLIC_VIEW_KEY);
        assertEq(offer.xmrPublicSpendKey, XMR_PUBLIC_SPEND_KEY);
        assertEq(offer.xmrPrivateViewKey, XMR_PRIVATE_VIEW_KEY);
    }

    function _assertRecoveredEscrowKeys(uint256 spendKey, uint256 viewKey) internal view {
        assertEq(spendKey, ESCROW_PRIVATE_SPEND_KEY);
        assertEq(viewKey, ESCROW_PRIVATE_VIEW_KEY);
        assertEq(_publicKey(spendKey), ESCROW_PUBLIC_SPEND_KEY);
        assertEq(_publicKey(viewKey), ESCROW_PUBLIC_VIEW_KEY);
    }

    function _combinePrivateKeys(uint256 left, uint256 right) internal pure returns (uint256) {
        return (left + right) % ED25519_L;
    }

    function _publicKey(uint256 privateKey) internal view returns (uint256) {
        return Ed25519.scalarMultBaseCompressed(privateKey);
    }
}
