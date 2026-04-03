
import { ConnectModal } from "./connectmodal";

export const Navbar = () => (
    <>
        <nav class="w-full flex justify-between px-2 pt-4 pb-2">
            <div class="font-bold text-xl">
                xmrp2p.eth
            </div>
            <div>
                <ConnectModal />
            </div>
        </nav>
    </>
);
