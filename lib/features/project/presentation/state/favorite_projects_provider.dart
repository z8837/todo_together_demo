import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todotogether/core/preferences/ui_preferences.dart';

final favoriteProjectIdsProvider =
    StateNotifierProvider<FavoriteProjectIdsNotifier, Set<String>>((ref) {
      return FavoriteProjectIdsNotifier();
    });

class FavoriteProjectIdsNotifier extends StateNotifier<Set<String>> {
  FavoriteProjectIdsNotifier() : super(UiPreferences.favoriteProjectIds());

  void toggle(String projectId) {
    final next = {...state};
    if (next.contains(projectId)) {
      next.remove(projectId);
    } else {
      next.add(projectId);
    }
    state = next;
    unawaited(UiPreferences.setFavoriteProjectIds(next));
  }

  void refresh() {
    state = UiPreferences.favoriteProjectIds();
  }
}
