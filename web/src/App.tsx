import { createSignal } from "solid-js";

import { Navbar } from "./components/navbar";

export const App = () => {
    const [count, setCount] = createSignal(0);

    return (
        <>
            <Navbar />
            <section>
                hello
            </section>
        </>
    );
};

export default App;
