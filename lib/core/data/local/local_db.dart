import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'entities/local_project_entity.dart';
import 'entities/local_todo_entity.dart';
import 'entities/local_user_entity.dart';

class LocalDB {
  const LocalDB._();

  static Isar? _isar;

  static Isar get instance {
    final isar = _isar;
    if (isar == null) {
      throw StateError('LocalDB.init() must be called before use.');
    }
    return isar;
  }

  static Future<void> init() async {
    if (_isar != null) {
      return;
    }
    final directory = await _resolveDirectory();
    _isar = await Isar.open([
      LocalUserEntitySchema,
      LocalProjectEntitySchema,
      LocalTodoEntitySchema,
    ], directory: directory.path);
  }

  static Future<Directory> _resolveDirectory() async {
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      return Directory.systemTemp.createTemp('todo_together_demo_test');
    }
    return getApplicationSupportDirectory();
  }
}
