import classnames from "classnames";
import { type Component } from "solid-js";
import { match } from "ts-pattern";

export const StatusBadge: Component<{ state: number; }> = (props) => {
  const config = () =>
    match(props.state)
      .with(1, () => ({
        label: "Open",
        className: "bg-(--thorin-green-surface) text-(--thorin-green-primary)",
      }))
      .with(2, () => ({
        label: "Taken",
        className: "bg-(--thorin-blue-surface) text-(--thorin-blue-primary)",
      }))
      .with(3, () => ({
        label: "Cancelled",
        className: "bg-(--thorin-grey-surface) text-(--thorin-grey-primary)",
      }))
      .with(4, () => ({
        label: "Refunded",
        className:
          "bg-(--thorin-orange-surface) text-(--thorin-orange-primary)",
      }))
      .with(5, () => ({
        label: "Ready",
        className:
          "bg-(--thorin-indigo-surface) text-(--thorin-indigo-primary)",
      }))
      .with(6, () => ({
        label: "Claimed",
        className:
          "bg-(--thorin-purple-surface) text-(--thorin-purple-primary)",
      }))
      .otherwise(() => null);

  const c = config();

  if (!c) return null;

  return (
    <span
      class={classnames(
        "text-xs font-medium px-1.5 py-0.5 whitespace-nowrap",
        c.className,
      )}
    >
      {c.label}
    </span>
  );
};
