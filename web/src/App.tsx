import { Navbar } from "./navbar";

export const App = () => (
    <div class="w-full max-w-7xl mx-auto space-y-4">
        <Navbar />
        <div class="flex gap-4">
            <section class="w-[400px] space-y-2">
                <h2 class="px-2">Create Offer</h2>
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
                    <button class="btn-primary w-full">
                        Create Order
                    </button>
                </div>
            </section>
            <section class="grow space-y-2">
                <h2 class="px-2">Your orders</h2>
                <div class="card p-4">
                    No open orders
                </div>
            </section>
        </div>
    </div>
);
