export const base58encode = (bytes: Uint8Array): string => {
    const alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    const base = BigInt(alphabet.length);

    // Count leading zeros
    let leadingZeros = 0;

    for (let i = 0; i < bytes.length && bytes[i] === 0; i++) {
        leadingZeros++;
    }

    // Convert byte array to a single BigInt
    let value = 0n;

    for (const byte of bytes) {
        value = (value << 8n) + BigInt(byte);
    }

    // Convert BigInt to base58 string
    let result = "";

    while (value > 0n) {
        const remainder = value % base;

        value /= base;
        result = alphabet[Number(remainder)] + result;
    }

    // Add leading '1's for leading zeros
    return "1".repeat(leadingZeros) + result;
};
