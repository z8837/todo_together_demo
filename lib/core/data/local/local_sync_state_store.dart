import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalSyncStateStore {
  const LocalSyncStateStore._();

  static const _fileName = 'local_sync_state.json';
  static _LocalSyncState? _state;
  static Future<_LocalSyncState>? _loading;

  static Future<Set<String>> deletedProjectIds() async {
    final state = await _ensureLoaded();
    return {...state.deletedProjectIds};
  }

  static Future<Set<String>> deletedTodoIds() async {
    final state = await _ensureLoaded();
    return {...state.deletedTodoIds};
  }

  static Future<void> markProjectDeleted(String projectId) async {
    final state = await _ensureLoaded();
    if (state.deletedProjectIds.add(projectId)) {
      await _persist(state);
    }
  }

  static Future<void> unmarkProjectDeleted(String projectId) async {
    final state = await _ensureLoaded();
    if (state.deletedProjectIds.remove(projectId)) {
      await _persist(state);
    }
  }

  static Future<void> markTodoDeleted(String todoId) async {
    final state = await _ensureLoaded();
    if (state.deletedTodoIds.add(todoId)) {
      await _persist(state);
    }
  }

  static Future<void> markTodosDeleted(Iterable<String> todoIds) async {
    final ids = todoIds.where((id) => id.trim().isNotEmpty).toSet();
    if (ids.isEmpty) {
      return;
    }
    final state = await _ensureLoaded();
    final beforeCount = state.deletedTodoIds.length;
    state.deletedTodoIds.addAll(ids);
    if (state.deletedTodoIds.length != beforeCount) {
      await _persist(state);
    }
  }

  static Future<void> unmarkTodoDeleted(String todoId) async {
    final state = await _ensureLoaded();
    if (state.deletedTodoIds.remove(todoId)) {
      await _persist(state);
    }
  }

  static Future<void> unmarkTodosDeleted(Iterable<String> todoIds) async {
    final ids = todoIds.where((id) => id.trim().isNotEmpty).toSet();
    if (ids.isEmpty) {
      return;
    }
    final state = await _ensureLoaded();
    final beforeCount = state.deletedTodoIds.length;
    state.deletedTodoIds.removeAll(ids);
    if (state.deletedTodoIds.length != beforeCount) {
      await _persist(state);
    }
  }

  static Future<_LocalSyncState> _ensureLoaded() async {
    final existing = _state;
    if (existing != null) {
      return existing;
    }
    final inFlight = _loading;
    if (inFlight != null) {
      return inFlight;
    }
    final next = _load();
    _loading = next;
    try {
      return await next;
    } finally {
      if (identical(_loading, next)) {
        _loading = null;
      }
    }
  }

  static Future<_LocalSyncState> _load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        final empty = _LocalSyncState.empty();
        _state = empty;
        return empty;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        final empty = _LocalSyncState.empty();
        _state = empty;
        return empty;
      }
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        final empty = _LocalSyncState.empty();
        _state = empty;
        return empty;
      }
      final loaded = _LocalSyncState.fromJson(json);
      _state = loaded;
      return loaded;
    } catch (_) {
      final empty = _LocalSyncState.empty();
      _state = empty;
      return empty;
    }
  }

  static Future<void> _persist(_LocalSyncState state) async {
    _state = state;
    try {
      final file = await _resolveFile();
      await file.writeAsString(jsonEncode(state.toJson()));
    } catch (_) {}
  }

  static Future<File> _resolveFile() async {
    final directory = await _resolveDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  static Future<Directory> _resolveDirectory() async {
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      return Directory.systemTemp.createTemp('todo_together_demo_sync_state');
    }
    return getApplicationSupportDirectory();
  }
}

class _LocalSyncState {
  _LocalSyncState({
    required this.deletedProjectIds,
    required this.deletedTodoIds,
  });

  factory _LocalSyncState.empty() {
    return _LocalSyncState(
      deletedProjectIds: <String>{},
      deletedTodoIds: <String>{},
    );
  }

  factory _LocalSyncState.fromJson(Map<String, dynamic> json) {
    Set<String> readSet(String key) {
      final value = json[key];
      if (value is! List) {
        return <String>{};
      }
      return value
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toSet();
    }

    return _LocalSyncState(
      deletedProjectIds: readSet('deleted_project_ids'),
      deletedTodoIds: readSet('deleted_todo_ids'),
    );
  }

  final Set<String> deletedProjectIds;
  final Set<String> deletedTodoIds;

  Map<String, dynamic> toJson() {
    return {
      'deleted_project_ids': deletedProjectIds.toList(growable: false),
      'deleted_todo_ids': deletedTodoIds.toList(growable: false),
    };
  }
}
