import { config as loadDotEnv } from "dotenv";
import { z } from "zod";

loadDotEnv();

const numericValueSchema = z.coerce.number()
    .finite("Expected a finite number")
    .nonnegative("Expected a non-negative number");

const envSchema = z
    .object({
        CONTRACT: z.string().trim()
            .min(1, "CONTRACT is required"),
        RPC: z
            .string()
            .trim()
            .min(1, "RPC is required")
            .transform(value =>
                value
                    .split(",")
                    .map(entry => entry.trim())
                    .filter(entry => entry.length > 0),
            )
            .pipe(z.array(z.string().url()).min(1, "At least one RPC URL is required")),
        MONERO_DAEMON: z.string().trim()
            .url("MONERO_DAEMON must be a valid URL"),
        MONERO_WALLET_RPC: z.string().trim()
            .url("MONERO_WALLET_RPC must be a valid URL"),
        LOOP_DELAY: z.coerce.number()
            .int("LOOP_DELAY must be an integer")
            .positive("LOOP_DELAY must be > 0"),
        MINXMR: numericValueSchema,
        MAXXMR: numericValueSchema,
        MINPRICE: numericValueSchema,
        MAXPRICE: numericValueSchema,
        ORACLE_RATIO: numericValueSchema,
        ORACLE_OFFSET: numericValueSchema,
        GAS_ALLOWANCE: numericValueSchema,
    })
    .superRefine((data, context) => {
        if (data.MINXMR > data.MAXXMR) {
            context.addIssue({
                code: z.ZodIssueCode.custom,
                path: ["MINXMR"],
                message: "MINXMR cannot be greater than MAXXMR",
            });
        }

        if (data.MINPRICE > data.MAXPRICE) {
            context.addIssue({
                code: z.ZodIssueCode.custom,
                path: ["MINPRICE"],
                message: "MINPRICE cannot be greater than MAXPRICE",
            });
        }
    });

export const appConfig = envSchema.parse(process.env);

export type AppConfig = typeof appConfig;
