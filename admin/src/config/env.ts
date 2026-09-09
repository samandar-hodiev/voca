// Typed environment configuration.
//
// Reads NEXT_PUBLIC_* values, which are PUBLIC by definition: anything prefixed this way is
// compiled into the browser bundle and readable by anyone.
//
// Therefore this file must only ever carry: the API base URL and the environment name.
//
// NEVER put here: the Azure Speech key, an AI provider key, the RevenueCat secret key, a
// database URL, or any server-side secret. The admin frontend holds no secrets, exactly as
// the mobile app holds none (ARCHITECTURE.md 45.2, 18.2).
