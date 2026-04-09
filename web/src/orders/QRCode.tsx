import encodeQR from "qr";
import { type Component, createMemo } from "solid-js";

export const QRCodeDisplay: Component<{ data: string; }> = (props) => {
  const svg = createMemo(() => {
    try {
      const raw = encodeQR(props.data, "svg", { scale: 1, border: 2 });

      return raw.replace(
        "<svg ",
        "<svg width=\"100%\" height=\"100%\" ",
      );
    }
    catch {
      return null;
    }
  });

  return (
    <div
      class="rounded-lg mx-auto overflow-hidden w-48 h-48 bg-white p-1"
      innerHTML={svg() ?? ""}
    />
  );
};
