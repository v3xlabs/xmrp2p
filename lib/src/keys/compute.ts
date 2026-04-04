import { Point } from "@noble/ed25519";
import { bytesToBigInt, numberToHex } from "viem";

export const computeEscrowWallet = ({
    evmPublicViewKey,
    xmrPrivateViewKey,
    evmPublicSpendKey,
    xmrPublicSpendKey,
}: {
    evmPublicViewKey: bigint;
    xmrPrivateViewKey: bigint;
    evmPublicSpendKey: bigint;
    xmrPublicSpendKey: bigint;
}, seed: string) => {
    const xmrPublicViewKeyPoint: Point = Point.BASE.multiply(xmrPrivateViewKey, true);
    const evmPublicViewKeyPoint: Point = Point.fromHex(numberToHex(evmPublicViewKey, { size: 32 }).slice(2, 66));
    const publicViewKeyPoint: Point = evmPublicViewKeyPoint.add(xmrPublicViewKeyPoint);
    const publicViewKey = bytesToBigInt(publicViewKeyPoint.toBytes());

    const xmrPublicSpendKeyPoint: Point = Point.fromHex(numberToHex(xmrPublicSpendKey, { size: 32 }).slice(2, 66));
    const evmPublicSpendKeyPoint: Point = Point.fromHex(numberToHex(evmPublicSpendKey, { size: 32 }).slice(2, 66));
    const publicSpendKeyPoint: Point = evmPublicSpendKeyPoint.add(xmrPublicSpendKeyPoint);
    const publicSpendKey = bytesToBigInt(publicSpendKeyPoint.toBytes());

    return {
        publicSpendKey,
        publicViewKey,
    };
};
