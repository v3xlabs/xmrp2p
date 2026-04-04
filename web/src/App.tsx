import { Navbar } from "./navbar";
import { OrderTable } from "./orders/OrderTable";

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
            </section>
            <div class="space-y-2 grow">
                <section class="grow space-y-2">
                    <h2 class="px-2">Your orders</h2>
                    <div class="card p-2">
                        <OrderTable orders={["1", "2", "3", "4", "5"]} />
                    </div>
                </section>

                <section class="grow space-y-2">
                    <h2 class="px-2">Order history</h2>
                    <div class="card p-4">
                        No open orders
                    </div>
                </section>

                <section class="grow space-y-2">
                    <h2 class="px-2">Open orders</h2>
                    <div class="card p-4">
                        No open orders
                    </div>
                </section>
            </div>
        </div>
    </div>
);
