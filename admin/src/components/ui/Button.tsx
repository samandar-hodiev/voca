/**
 * Button.
 *
 * Three levels of emphasis, matching the mobile app's hierarchy so the two products feel
 * like one. Every variant keeps a visible focus ring, a real disabled state, and a
 * loading state that preserves width so the layout does not jump.
 */
import type { ButtonHTMLAttributes, ReactNode } from "react";

type Variant = "primary" | "secondary" | "ghost";
type Size = "sm" | "md";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  isLoading?: boolean;
  children: ReactNode;
}

const base =
  "inline-flex items-center justify-center gap-2 rounded-[--radius-md] font-medium " +
  "transition-colors duration-150 disabled:cursor-not-allowed select-none";

const variants: Record<Variant, string> = {
  primary:
    "bg-primary text-on-primary hover:bg-primary-pressed " +
    "disabled:bg-border disabled:text-text-disabled",
  secondary:
    "border border-border-strong text-primary bg-transparent hover:bg-primary-muted " +
    "disabled:border-border disabled:text-text-disabled disabled:hover:bg-transparent",
  ghost:
    "text-primary bg-transparent hover:bg-primary-muted " +
    "disabled:text-text-disabled disabled:hover:bg-transparent",
};

// min-h-9 / min-h-11 keep a comfortable pointer target without the 48px floor mobile
// needs: a mouse is more precise than a thumb.
const sizes: Record<Size, string> = {
  sm: "min-h-9 px-3 text-sm",
  md: "min-h-11 px-4 text-sm",
};

export function Button({
  variant = "primary",
  size = "md",
  isLoading = false,
  disabled,
  children,
  className = "",
  ...rest
}: ButtonProps) {
  return (
    <button
      {...rest}
      disabled={disabled || isLoading}
      aria-busy={isLoading || undefined}
      className={`${base} ${variants[variant]} ${sizes[size]} ${className}`}
    >
      {isLoading ? <Spinner /> : children}
    </button>
  );
}

function Spinner() {
  return (
    <span
      role="status"
      aria-label="Loading"
      className="size-4 animate-spin rounded-full border-2 border-current border-t-transparent"
    />
  );
}
