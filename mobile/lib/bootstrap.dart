// Application bootstrap, shared by every flavor.
//
// Responsibility: initialize the Riverpod container, error and crash handlers, analytics,
// secure storage, localization, and remote config, then run the app.
//
// Registers the global error handlers so an uncaught exception is reported rather than lost.
