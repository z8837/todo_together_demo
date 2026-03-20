import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/holiday.dart';

final holidaysProvider = Provider<AsyncValue<List<Holiday>>>((ref) {
  return const AsyncValue.data(<Holiday>[]);
});

class HolidaySyncCoordinator {
  const HolidaySyncCoordinator();

  Future<void> ensureHolidaysSynced() async {}

  Future<void> clearCachedHolidays() async {}
}

final holidaySyncCoordinatorProvider = Provider<HolidaySyncCoordinator>((ref) {
  return const HolidaySyncCoordinator();
});
