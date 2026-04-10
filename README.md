# xmrp2p.eth
Atomic EVM <-> XMR Peer-to-Peer Swaps

## Try it out

You can tryit out at [xmrp2p.eth](http://xmrp2p.eth).

## How it works

TODO: write this section
TLDR;
- evm contract enforces rules, code-is-law,
- at the start of a trade both parties commit to a public viewing & spending keys,
- both parties put up the required evm funds or a deposit,
- xmr escrow address is derived from combined public keys,
- to complete trade xmr-side reveals their private key, deposit is returned, and funds are transferred
- cancelling/quitting can be done via revealing your side of the keys
- xmr escrow can be recovered due to 2/2 keys being known to one of the two parties

## Attribution

This repository was inspired by [moneroswap](https://codeberg.org/moneroswap/moneroswap) & [AthanorLabs/atomic-swap](https://github.com/AthanorLabs/atomic-swap).

Built at ETHGlobal Cannes 2026 by [V1rtl](https://v1rtl.site), [Jonte](https://jontes.page), [Carline](https://carline.sh) & [Luc](https://luc.computer/).
