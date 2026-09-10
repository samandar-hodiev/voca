/**
 * Loading, error and empty states.
 *
 * The same three states the mobile app defines, adapted for the web. Deliberately plain:
 * an over-designed failure is still a failure.
 */
import type { ReactNode } from "react";

import { Button } from "./Button";

export function LoadingState({ message = "Loading" }: { message?: string }) {
  return (
    <div role="status" aria-live="polite" className="flex flex-col items-center gap-3 py-12">
      <span className="size-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      <p className="text-sm text-text-secondary">{message}</p>
    </div>
  );
}

/** A shaped placeholder. Feels faster than a spinner because the layout does not shift. */
export function Skeleton({ className = "h-4 w-full" }: { className?: string }) {
  return <div aria-hidden className={`animate-pulse rounded-[--radius-sm] bg-border ${className}`} />;
}

export function ErrorState({
  title = "Something went wrong",
  message,
  onRetry,
  requestId,
}: {
  title?: string;
  message: string;
  onRetry?: () => void;
  requestId?: string;
}) {
  return (
    <div role="alert" className="flex flex-col items-center gap-3 py-12 text-center">
      <h3 className="text-base font-semibold text-text-primary">{title}</h3>
      <p className="max-w-md text-sm text-text-secondary">{message}</p>
      {onRetry && (
        <Button variant="secondary" size="sm" onClick={onRetry}>
          Retry
        </Button>
      )}
      {/* Quotable in a bug report: it maps to a backend log line. */}
      {requestId && <code className="text-xs text-text-disabled">{requestId}</code>}
    </div>
  );
}

export function EmptyState({
  title,
  message,
  action,
}: {
  title: string;
  message?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center gap-3 py-12 text-center">
      <h3 className="text-base font-semibold text-text-primary">{title}</h3>
      {message && <p className="max-w-md text-sm text-text-secondary">{message}</p>}
      {action}
    </div>
  );
}
