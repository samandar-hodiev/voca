// core/config: values supplied at build time via --dart-define.
//
// API_BASE_URL, APP_ENV, REVENUECAT_PUBLIC_SDK_KEY, ANALYTICS_PUBLIC_KEY, SENTRY_DSN,
// GOOGLE_CLIENT_ID.
//
// NO SERVER SECRET EVER APPEARS HERE. The app never holds an Azure key, a RevenueCat secret
// key, or a database credential — only public client identifiers. This is a hard rule
// (ARCHITECTURE.md 4.5, 18.2, 25.2).
