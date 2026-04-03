import { createSignal } from "solid-js";

import { Navbar } from "./components/navbar";

export const App = () => {
    const [count, setCount] = createSignal(0);

    return (
        <div class="w-full max-w-7xl mx-auto space-y-4">
            <Navbar />
            <div class="flex gap-4">
                <section class="w-[400px] space-y-2">
                    <h2 class="px-2">Create Offer</h2>
                    <div class="card p-4">
                        <input placeholder="0" />
                        <input placeholder="0" />
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
};

export default App;
