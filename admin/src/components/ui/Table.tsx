/**
 * Table primitives.
 *
 * The admin is a data tool, so the table is a foundation piece rather than an
 * afterthought. Semantic <table> markup is used deliberately: a div grid pretending to be
 * a table loses row and column navigation for screen reader users.
 *
 * The wrapper scrolls horizontally so a wide table never forces the whole page sideways.
 */
import type { ReactNode } from "react";

export function Table({ children, caption }: { children: ReactNode; caption?: string }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse text-sm">
        {caption && <caption className="sr-only">{caption}</caption>}
        {children}
      </table>
    </div>
  );
}

export function THead({ children }: { children: ReactNode }) {
  return <thead className="border-b border-border">{children}</thead>;
}

export function TBody({ children }: { children: ReactNode }) {
  return <tbody>{children}</tbody>;
}

export function TR({ children }: { children: ReactNode }) {
  return <tr className="border-b border-border last:border-0">{children}</tr>;
}

export function TH({ children, numeric = false }: { children: ReactNode; numeric?: boolean }) {
  return (
    <th
      scope="col"
      className={`px-3 py-2.5 text-xs font-semibold uppercase tracking-wide text-text-secondary ${
        numeric ? "text-right" : "text-left"
      }`}
    >
      {children}
    </th>
  );
}

export function TD({ children, numeric = false }: { children: ReactNode; numeric?: boolean }) {
  return (
    <td
      className={`px-3 py-3 text-text-primary ${
        // Tabular figures keep numeric columns aligned, which is what makes a data table
        // readable at a glance.
        numeric ? "text-right tabular-nums" : "text-left"
      }`}
    >
      {children}
    </td>
  );
}
