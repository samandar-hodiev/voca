/**
 * The application shell: sidebar, header and the scrolling content column.
 *
 * A skip link comes first in the DOM so a keyboard user can jump past the navigation,
 * which is the single most valuable accessibility affordance in a sidebar layout.
 */
import type { ReactNode } from "react";

import { Header } from "./Header";
import { Sidebar } from "./Sidebar";

export function AppShell({
  title,
  description,
  actions,
  children,
}: {
  title: string;
  description?: string;
  actions?: ReactNode;
  children: ReactNode;
}) {
  return (
    <div className="flex h-dvh overflow-hidden bg-background">
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-50 focus:rounded-[--radius-md] focus:bg-surface focus:px-4 focus:py-2 focus:text-sm"
      >
        Skip to content
      </a>

      <Sidebar />

      <div className="flex min-w-0 flex-1 flex-col">
        <Header title={title} description={description} actions={actions} />
        <main id="main" className="min-h-0 flex-1 overflow-y-auto">
          <div className="mx-auto w-full max-w-6xl px-6 py-6">{children}</div>
        </main>
      </div>
    </div>
  );
}
