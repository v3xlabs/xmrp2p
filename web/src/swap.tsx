import { SegmentedControl } from "@kobalte/core/segmented-control";
import { For } from "solid-js";

export const Swap = () => {
    console.log("placeholder");

    return (
        <div class="card p-4 space-y-2">
            <div>
                <label for="input_amount" class="text-sm">
                    Sell
                </label>
                <input placeholder="0" class="input w-full" id="input_amount" />
            </div>
            <div>
                <label for="output_amount" class="text-sm">
                    Buy
                </label>
                <input placeholder="0" class="input w-full" id="output_amount" />
            </div>
            <div>
                <SegmentedControl class="flex justify-between gap-2" defaultValue="1">
                    <SegmentedControl.Label class="segmented-control__label">
                        Slippage
                    </SegmentedControl.Label>
                    <div class="w-fit border border-(--thorin-border) rounded-md relative overflow-hidden" role="presentation">
                        <SegmentedControl.Indicator class="absolute bottom-0 h-1 bg-(--thorin-blue-primary) transition-all" />
                        <div class="inline-flex flex-row divide-x divide-(--thorin-border)" role="presentation">
                            <For each={["3%", "5%", "10%"]}>
                                {slippage => (
                                    <SegmentedControl.Item value={slippage} class="relative px-2">
                                        <SegmentedControl.ItemInput class="" />
                                        <SegmentedControl.ItemLabel class="data-checked:text-(--thorin-text-accent) not-data-checked:cursor-pointer data-checked:pointer-none">
                                            {slippage}
                                        </SegmentedControl.ItemLabel>
                                    </SegmentedControl.Item>
                                )}
                            </For>
                        </div>
                    </div>
                </SegmentedControl>
            </div>
            <button class="btn-primary btn-lg w-full" disabled>
                Create Order
            </button>
        </div>
    );
};
