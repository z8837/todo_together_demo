class UiPreferences {
  const UiPreferences._();

  static String _projectListViewMode = 'detail';
  static bool _projectFavoritesOnly = false;
  static bool _projectPickerFavoritesOnly = false;
  static bool _scheduleFavoritesOnly = false;
  static Set<String> _favoriteProjectIds = <String>{};

  static String projectListViewMode() => _projectListViewMode;

  static bool projectFavoritesOnly() => _projectFavoritesOnly;

  static bool projectPickerFavoritesOnly() => _projectPickerFavoritesOnly;

  static bool scheduleFavoritesOnly() => _scheduleFavoritesOnly;

  static Set<String> favoriteProjectIds() => {..._favoriteProjectIds};

  static Future<void> setProjectListViewMode(String value) async {
    _projectListViewMode = value;
  }

  static Future<void> setProjectFavoritesOnly(bool value) async {
    _projectFavoritesOnly = value;
  }

  static Future<void> setProjectPickerFavoritesOnly(bool value) async {
    _projectPickerFavoritesOnly = value;
  }

  static Future<void> setScheduleFavoritesOnly(bool value) async {
    _scheduleFavoritesOnly = value;
  }

  static Future<void> setFavoriteProjectIds(Set<String> value) async {
    _favoriteProjectIds = {...value};
  }
}
