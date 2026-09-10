/// Development flavor entrypoint. Points at the local backend.
///
/// Configuration arrives through --dart-define and carries PUBLIC VALUES ONLY
/// (ARCHITECTURE.md 25.2).
library;

import 'bootstrap.dart';
import 'core/config/flavor.dart';

void main() => bootstrap(Flavor.dev);
