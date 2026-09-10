/// Default entrypoint. Runs the development flavor.
///
/// Thin on purpose: it delegates to [bootstrap] and decides nothing
/// (ARCHITECTURE.md 27).
library;

import 'bootstrap.dart';
import 'core/config/flavor.dart';

void main() => bootstrap(Flavor.dev);
