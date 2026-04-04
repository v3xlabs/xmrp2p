
import { ChainSelector } from "./chain";
import { UserProfile } from "./profile";

export const Navbar = () => (
  <>
    <nav class="w-full flex justify-between px-2 pt-4 pb-2">
      <div class="font-bold text-xl">
        xmrp2p.eth
      </div>
      <div class="flex items-center gap-2">
        <ChainSelector />
        <UserProfile />
      </div>
    </nav>
  </>
);
