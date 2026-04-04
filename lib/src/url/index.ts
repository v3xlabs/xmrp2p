import { bytesToHex } from "@noble/hashes/utils.js";

export const createMoneroUrlView = (offer: Offer) => {
    const wallet = generateOfferMoneroWallet(offer, seed);

    // URI syntax is defined in https://github.com/monero-project/monero/wiki/URI-Formatting
    // the label parameter is CakeWallet supported
    return "monero_wallet:" + wallet.address
      + "?address=" + wallet.address
      + "&view_key=" + bytesToHex(numberToBytes(wallet.privateViewKey, { size: 32 }).reverse()).slice(2)
      + "&label=MS-" + this.chainId + "-" + this.contractAddress?.slice(2, 10) + "-" + offer.id + "-V";
};
