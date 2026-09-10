/**
 * Card.
 *
 * The admin's resting surface. Unlike mobile, it is opaque: glass is a mobile idiom, and
 * translucency behind a dense data table hurts readability for no benefit
 * (ARCHITECTURE.md 44).
 */
import type { ReactNode } from "react";

interface CardProps {
  children: ReactNode;
  title?: string;
  description?: string;
  actions?: ReactNode;
  className?: string;
}

export function Card({ children, title, description, actions, className = "" }: CardProps) {
  return (
    <section
      className={`rounded-[--radius-lg] border border-border bg-surface ${className}`}
    >
      {(title || actions) && (
        <header className="flex items-start justify-between gap-4 border-b border-border px-5 py-4">
          <div>
            {title && <h2 className="text-base font-semibold text-text-primary">{title}</h2>}
            {description && (
              <p className="mt-0.5 text-sm text-text-secondary">{description}</p>
            )}
          </div>
          {actions}
        </header>
      )}
      <div className="px-5 py-4">{children}</div>
    </section>
  );
}
