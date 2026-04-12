import { Navbar } from "./navbar";
import { OrderTable } from "./orders/OrderTable";
import { SettingsButton } from "./settings";
import { Swap } from "./swap";

export const App = () => (
  <div class="min-h-screen w-full max-w-[1600px] mx-auto px-4 py-4 md:py-6 flex flex-col gap-4">
    <Navbar />
    <div class="flex-1 min-h-0 flex gap-4 flex-col xl:flex-row">
      <section class="w-full xl:w-[380px] xl:min-w-[380px] space-y-2">
        <div class="flex justify-between items-center">
          <h2 class="px-2">Create Offer</h2>
          <SettingsButton />
        </div>
        <Swap />
      </section>
      <div class="flex-1 min-h-[60vh] xl:min-h-0 space-y-2">
        <section class="h-full space-y-2">
          <OrderTable />
        </section>
      </div>
    </div>
    {/* <SolidQueryDevtools /> */}
  </div>
);
