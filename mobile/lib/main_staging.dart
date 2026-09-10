/// Staging flavor entrypoint.
///
/// Points at the staging API and a separate analytics project. Distributed through
/// TestFlight and Play internal testing (ARCHITECTURE.md 25.1).
library;

import 'bootstrap.dart';
import 'core/config/flavor.dart';

void main() => bootstrap(Flavor.staging);
