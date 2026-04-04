const WEI_DECIMALS = 18n;
const PICONERO_DECIMALS = 12n;

export const WEIS_PER_ETH = 10n ** WEI_DECIMALS;
export const PICONEROS_PER_XMR = 10n ** PICONERO_DECIMALS;

const bigintPow10 = (decimals: number): bigint => 10n ** BigInt(decimals);

const parseUnitsDecimal = ({
    value,
    decimals,
}: {
    value: string;
    decimals: number;
}): bigint => {
    const normalized = value.trim();

    if (normalized.length === 0) {
        throw new Error("Expected non-empty numeric value");
    }

    const sign = normalized.startsWith("-") ? -1n : 1n;
    const unsigned = normalized.replace(/^[+-]/, "");
    const firstDot = unsigned.indexOf(".");
    const hasDot = firstDot !== -1;
    const wholePart = hasDot ? unsigned.slice(0, firstDot) : unsigned;
    const fractionalPart = hasDot ? unsigned.slice(firstDot + 1) : "";

    if (hasDot && fractionalPart.includes(".")) {
        throw new Error(`Invalid numeric value: ${value}`);
    }

    if (!/^\d+$/.test(wholePart || "0") || !/^\d*$/.test(fractionalPart)) {
        throw new Error(`Invalid numeric value: ${value}`);
    }

    const fraction = fractionalPart.slice(0, decimals).padEnd(decimals, "0");
    const whole = BigInt(wholePart || "0") * bigintPow10(decimals);
    const frac = BigInt(fraction || "0");

    return sign * (whole + frac);
};

export const parseEthValueToWei = (value: string | number | bigint): bigint => {
    if (typeof value === "bigint") return value;

    if (typeof value === "number") return parseUnitsDecimal({ value: String(value), decimals: 18 });

    return value.includes(".") ? parseUnitsDecimal({ value, decimals: 18 }) : BigInt(value);
};

export const parseXmrValueToPiconeros = (value: string | number | bigint): bigint => {
    if (typeof value === "bigint") return value;

    if (typeof value === "number") return parseUnitsDecimal({ value: String(value), decimals: 12 });

    return value.includes(".") ? parseUnitsDecimal({ value, decimals: 12 }) : BigInt(value);
};

export const clamp = ({
    value,
    min,
    max,
}: {
    value: bigint;
    min: bigint;
    max: bigint;
}): bigint => {
    if (min > max) throw new Error("Invalid clamp bounds: min > max");

    if (value < min) return min;

    if (value > max) return max;

    return value;
};

export const resolveOfferPrice = ({
    fixedPrice,
    oraclePrice,
    oracleRatio,
    oracleOffset,
    minPrice,
    maxPrice,
    ratioDenominator = 1_000_000_000_000_000_000n,
}: {
    fixedPrice: bigint;
    oraclePrice: bigint;
    oracleRatio: bigint;
    oracleOffset: bigint;
    minPrice: bigint;
    maxPrice: bigint;
    ratioDenominator?: bigint;
}): bigint => {
    if (minPrice > maxPrice) {
        throw new Error("Invalid price range: minPrice > maxPrice");
    }

    if (fixedPrice > 0n) {
        return clamp({ value: fixedPrice, min: minPrice, max: maxPrice });
    }

    const dynamicPrice = (oraclePrice * oracleRatio) / ratioDenominator + oracleOffset;

    return clamp({ value: dynamicPrice, min: minPrice, max: maxPrice });
};

export const normalizeXmrBounds = ({
    minXmr,
    maxXmr,
}: {
    minXmr: bigint;
    maxXmr: bigint;
}): { minXmr: bigint; maxXmr: bigint; } => {
    if (minXmr < 0n || maxXmr < 0n) {
        throw new Error("XMR bounds cannot be negative");
    }

    if (minXmr > maxXmr) {
        throw new Error("Invalid XMR bounds: minXmr > maxXmr");
    }

    return { minXmr, maxXmr };
};
