// core/di: the composition root — root Riverpod providers.
//
// Riverpod is both the state layer and the dependency injection container. Each layer is a
// provider:
//
//   dioProvider -> remoteDataSourceProvider -> repositoryProvider -> useCaseProvider
//               -> controllerProvider
//
// Because every dependency is a provider, tests override the repository provider with a fake
// and the whole widget tree runs without a network (ARCHITECTURE.md 4.3, 22.2).
