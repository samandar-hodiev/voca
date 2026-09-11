/// Profile state for every screen that shows the signed-in person.
///
/// One provider rather than a fetch per screen: Home's greeting, the header avatar and the
/// Profile tab all read the same answer, so it is loaded once and shared.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ProfileRemoteDataSource(ref.watch(dioProvider)),
    apiBaseUrl: ref.watch(appConfigProvider).apiBaseUrl,
  );
});

final getProfileProvider = Provider<GetProfile>((ref) {
  return GetProfile(ref.watch(profileRepositoryProvider));
});

/// The signed-in person. Invalidate it after anything that changes the profile.
final profileProvider = FutureProvider<Profile>((ref) async {
  final result = await ref.watch(getProfileProvider)();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});
