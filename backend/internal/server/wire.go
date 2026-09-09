// server: the composition root — the ONLY place that knows the full object graph.
//
// Constructs the pgx pool, builds each repository, selects provider adapters from
// configuration (SPEECH_PROVIDER, PAYMENT_PROVIDER, ANALYTICS_PROVIDER,
// NOTIFICATION_PROVIDER, CACHE_DRIVER), injects repositories and ports into services,
// injects services into handlers, and registers routes.
//
// Manual constructor injection. NO DI framework: a monolith with about ten modules does not
// need one, and explicit wiring is far easier for a new Go developer to read.
//
// This is also where cross-module dependencies are made explicit — for example
// PronunciationService receiving subscription.Service. If a wiring line looks wrong here,
// the module boundary is wrong.
//
// See ARCHITECTURE.md 5.7, 5.5, 7.3.

package server
