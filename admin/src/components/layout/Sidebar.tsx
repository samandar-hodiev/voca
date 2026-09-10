/**
 * Navigation sidebar.
 *
 * Lists the admin capabilities from ARCHITECTURE.md 38.5. Every destination is present so
 * the shape of the tool is visible, and each is marked as unavailable until its feature
 * task lands — an honest disabled entry beats a link that leads nowhere.
 */
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

interface NavItem {
  label: string;
  href: string;
  /** False until the feature is built. */
  ready: boolean;
}

const items: NavItem[] = [
  { label: "Dashboard", href: "/", ready: true },
  { label: "Users", href: "/users", ready: false },
  { label: "Content", href: "/content", ready: false },
  { label: "Pronunciation", href: "/pronunciation", ready: false },
  { label: "Analytics", href: "/analytics", ready: false },
  { label: "Subscriptions", href: "/subscriptions", ready: false },
  { label: "Notifications", href: "/notifications", ready: false },
  { label: "System", href: "/system", ready: false },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <nav
      aria-label="Main"
      className="flex h-full w-60 shrink-0 flex-col gap-1 border-r border-border bg-surface px-3 py-4"
    >
      <div className="px-2 pb-4">
        <span className="text-base font-semibold text-text-primary">Voca</span>
        <span className="ml-2 text-xs text-text-secondary">Admin</span>
      </div>

      {items.map((item) =>
        item.ready ? (
          <Link
            key={item.href}
            href={item.href}
            aria-current={pathname === item.href ? "page" : undefined}
            className={`rounded-[--radius-md] px-3 py-2 text-sm transition-colors ${
              pathname === item.href
                ? "bg-primary-muted font-medium text-primary"
                : "text-text-secondary hover:bg-primary-muted hover:text-primary"
            }`}
          >
            {item.label}
          </Link>
        ) : (
          <span
            key={item.href}
            aria-disabled
            title="Not implemented yet"
            className="cursor-not-allowed rounded-[--radius-md] px-3 py-2 text-sm text-text-disabled"
          >
            {item.label}
          </span>
        ),
      )}
    </nav>
  );
}
