import { Navbar } from "./navbar";
import { OrderTable } from "./orders/OrderTable";
import { Swap } from "./swap";

export const App = () => (
    <div class="w-full max-w-7xl mx-auto space-y-4">
        <Navbar />
        <div class="flex gap-4">
            <section class="w-[400px] space-y-2">
                <h2 class="px-2">Create Offer</h2>
                <Swap />
            </section>
            <div class="space-y-2 grow">
                <section class="grow space-y-2">
                    <h2 class="px-2">Your orders</h2>
                    <div class="card p-2">
                        <OrderTable orders={["1", "2", "3", "4", "5"]} />
                    </div>
                </section>
            </div>
        </div>
    </div>
);
