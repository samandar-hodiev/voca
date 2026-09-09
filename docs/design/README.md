# Voca design language

Mobile and admin are separate applications with separate implementations. They share a
**design language**, not code.

```
Voca design language  (this folder: tokens and principles)
        │
        ├── Flutter implementation   mobile/lib/core/theme
        └── Admin implementation     admin/src/components/ui + Tailwind config
```

## What is shared

Color tokens and their semantic meaning, typography scale and hierarchy, spacing scale,
corner radius scale, elevation, iconography style, motion principles, and accessibility
rules such as minimum contrast and minimum touch target.

Score bands are part of this shared language and are defined **server-side**
(`ARCHITECTURE.md` section 6.4), so a score never looks "good" in one application and
"poor" in the other.

## What is not shared

Components. A Flutter widget and a React component solve different problems on different
platforms. Attempting to share them produces an abstraction that fits neither.

## Contents, to be filled during design work

| File | Purpose |
|------|---------|
| `tokens.md` | The canonical token values, with the name each platform uses |
| `typography.md` | Type scale, weights, and the Uzbek Latin rendering requirements |
| `accessibility.md` | Contrast, touch targets, screen reader expectations |

Nothing here is written yet. Design work is a separate task from architecture.
