// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;
import "./Enums.sol";

/// The Offer structure is used to describe both buy and sell offers
struct Offer {
    /// Type of offer
    OfferType type_;
    /// State of the offer
    OfferState state;
    /// Flag indicating wheter the offer was funded via a FundingRequest or not
    bool funded;
    /// Owner of the offer, the address which called create{Buy,Sell}Offer
    address owner;
    /// Manager of the offer, another address able to change the price. Only the owner can later change the manager.
    address manager;
    /// Counterparty of the offer. This can be set at creation time, in which case only that counterparty can take the offer,
    /// or will be filled when the offer is taken.
    address counterparty;
    /// Id of the offer
    uint256 id;
    /// Maximum trade amount (in wei). This is set from the value transfered during the call to create{Buy,Sell}Offer
    /// and updated by calls to update{Buy,Sell}Offer
    uint256 maxamount;
    /// Fixed price of the offer, in wei per XMR
    uint256 price;
    /// Minimum amount of XMR the owner is willing to buy (Buy offers)
    uint256 minxmr;
    /// Maximum amount of XMR the owner is willing to sell (Sell offers)
    uint256 maxxmr;
    /// Deposit related to the offer
    uint256 deposit;
    /// Timestamp when the offer was created or last updated (so users can asses of its freshness)
    uint256 lastupdate;
    /// Block number when the offer was taken. This is needed so retrieving messages can be done from a specific block.
    uint256 blockTaken;
    /// Monero ublic spend key of the EVM side of the trade
    uint256 evmPublicSpendKey;
    /// Monero private spend key of the EVM side of the trade. Set during a call to refund.
    uint256 evmPrivateSpendKey;
    /// Public view key provided by the EVM side of the trade. This is needed to compute the Monero address
    /// and to verify the private view key during a refund as the private view key may have been generated in a non standard way
    uint256 evmPublicViewKey;
    /// Monero private view key of the EVM side of the trade. Set during a call to refund.
    uint256 evmPrivateViewKey;
    /// Monero public spend key of the XMR side of the trade
    uint256 xmrPublicSpendKey;
    /// Monero private spend key of the XMR side of the trade. Set during a call to claim
    uint256 xmrPrivateSpendKey;
    /// Monero private view key of the XMR side of the trade. The EVM side of the trade doesn't need to share its private view key.
    uint256 xmrPrivateViewKey;
    /// index of the offer in the id list
    uint256 index;
    /// Final price of the taken offer, in wei per XMR
    uint256 finalprice;
    /// Amount to refund to the offer taker, in wei
    uint256 takerDeposit;
    /// Final amount of XMR of the taken offer (in piconeros)
    uint256 finalxmr;
    /// Timestamp until which 'ready' can be called, after, taken offer is considered in the READY state
    uint256 t0;
    /// Timestamp after which 'claim' can be called, after, taken offer can be refunded
    uint256 t1;
}

/// The FundingRequest structure describes funding requested by a Monero seller.
/// Since creating a sell offer requires a deposit in the EVM currency, Monero sellers may
/// not hold a sufficiently large amount of that currency to be able to place their offer.
/// Funding requests allow Monero sellers to request that their deposit be funded by a third party which they
/// will reward with a fee after a successful sale.
struct FundingRequest {
    /// This is the requester of the funding, this address will be able to create a sell offer or take a buy offer with the funding amount as deposit
    address requester;
    /// The requested funding amount (in wei)
    uint256 amount;
    /// The offered fee (in wei). If this funding request is funded and it is used in a completed swap, the funder will receive the fee.
    uint256 fee;
    /// The address of the funder
    address funder;
    /// Index in the activeFundingRequesters array
    uint256 index;
    /// Id of the offer which used the funding as deposit
    uint256 usedby;
    /// Timestamp when the request was funded. This is used by the funder to determine if it should wait or defund.
    uint256 fundedOn;
}
