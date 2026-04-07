
import logo from "../../public/logo_dark.svg";
import { ChainSelector } from "./chain";
import { UserProfile } from "./profile";

export const Navbar = () => (
  <>
    <nav class="w-full flex justify-between px-4 pt-4 md:pt-6 pb-2">
      <div class="flex items-center gap-2 px-2">
        <img src={logo} alt="xmrp2p.eth" class="h-10" />
        <div>
          <div class="font-bold text-xl leading-none">
            xmrp2p.eth
          </div>
          <div class="text-sm text-(--thorin-text-secondary) leading-none">
            Atomic Peer-to-Peer XMR/ETH Swaps
          </div>
        </div>
      </div>
      <div class="flex items-center gap-2 z-10">
        <ChainSelector />
        <UserProfile />
      </div>
    </nav>
  </>
);
