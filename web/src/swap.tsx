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
                <label for="output_amount" class="text-sm">
                    Slippage
                </label>
                <div>
                    <input type="range" min="0" max="100" value="10" class="w-full" />
                </div>
            </div>
            <button class="btn-primary w-full" disabled>
                Create Order
            </button>
        </div>
    );
};
