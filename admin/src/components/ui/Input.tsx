/**
 * Text input with label, helper and error affordances.
 *
 * The label is bound to the control with htmlFor/id, and the error is announced through
 * aria-describedby and role="alert" — a red border alone is invisible to a screen reader
 * and to anyone who cannot distinguish the colour.
 */
import type { InputHTMLAttributes } from "react";
import { useId } from "react";

interface InputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, "id"> {
  label?: string;
  helperText?: string;
  errorText?: string;
}

export function Input({ label, helperText, errorText, className = "", ...rest }: InputProps) {
  const id = useId();
  const describedBy = errorText || helperText ? `${id}-desc` : undefined;

  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={id} className="text-sm font-medium text-text-primary">
          {label}
        </label>
      )}
      <input
        {...rest}
        id={id}
        aria-invalid={errorText ? true : undefined}
        aria-describedby={describedBy}
        className={
          "min-h-11 rounded-[--radius-md] border bg-surface px-3 text-sm " +
          "text-text-primary placeholder:text-text-secondary " +
          "disabled:cursor-not-allowed disabled:text-text-disabled " +
          (errorText ? "border-error " : "border-border ") +
          className
        }
      />
      {(errorText || helperText) && (
        <p
          id={describedBy}
          role={errorText ? "alert" : undefined}
          className={`text-xs ${errorText ? "text-error" : "text-text-secondary"}`}
        >
          {errorText ?? helperText}
        </p>
      )}
    </div>
  );
}
