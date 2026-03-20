import 'dart:convert';

import 'package:dio/dio.dart';

class DemoHttpClientAdapter implements HttpClientAdapter {
  DemoHttpClientAdapter();

  static final _owner = {
    'id': 1,
    'email': 'demo@todo-together.app',
    'nickname': '데모 오너',
    'provider': 'mock',
  };

  static final _member = {
    'id': 2,
    'email': 'design@todo-together.app',
    'nickname': '디자인 메이커',
    'provider': 'mock',
  };

  static final _writer = {
    'id': 3,
    'email': 'writer@todo-together.app',
    'nickname': '콘텐츠 라이터',
    'provider': 'mock',
  };

  static final _qa = {
    'id': 4,
    'email': 'qa@todo-together.app',
    'nickname': 'QA 파트너',
    'provider': 'mock',
  };

  static final List<Map<String, dynamic>> _users = [
    _owner,
    _member,
    _writer,
    _qa,
  ];

  static final List<Map<String, dynamic>> _projects = [
    {
      'id': 'project-demo-app',
      'name': 'Todo Together Demo 앱',
      'description': '공개 포트폴리오 버전으로 재구성한 프로젝트',
      'version': 3,
      'owner': _owner,
      'membership': [
        {'user': _owner, 'role': 'owner'},
        {'user': _member, 'role': 'writer'},
      ],
      'recent_update_at': '2026-03-20T09:00:00.000',
      'created_at': '2026-03-18T09:00:00.000',
      'updated_at': '2026-03-20T09:00:00.000',
    },
    {
      'id': 'project-widget',
      'name': 'HomeWidget 위젯 정리',
      'description': '선택 날짜와 오늘 할 일을 위젯 데이터로 내보내는 흐름',
      'version': 2,
      'owner': _owner,
      'membership': [
        {'user': _owner, 'role': 'owner'},
      ],
      'recent_update_at': '2026-03-19T16:30:00.000',
      'created_at': '2026-03-17T11:00:00.000',
      'updated_at': '2026-03-19T16:30:00.000',
    },
  ];

  static final List<Map<String, dynamic>> _todos = [
    {
      'id': 'todo-1',
      'project': 'project-demo-app',
      'title': 'Isar 컬렉션 구조 정리',
      'status': 'doing',
      'kind': 'schedule',
      'version': 1,
      'created_by': _owner,
      'assignees': [_owner],
      'is_recurring': false,
      'is_hidden': false,
      'start_date': '2026-03-20',
      'start_time': null,
      'weekday_mask': null,
      'end_date': '2026-03-20',
      'end_time': '23:59:59',
      'alarm_offset_minutes': null,
      'completed_at': null,
      'created_at': '2026-03-19T10:00:00.000',
      'updated_at': '2026-03-20T08:30:00.000',
    },
    {
      'id': 'todo-2',
      'project': 'project-demo-app',
      'title': 'ProjectListFragment 카드 UI 맞추기',
      'status': 'todo',
      'kind': 'schedule',
      'version': 1,
      'created_by': _owner,
      'assignees': [_member],
      'is_recurring': false,
      'is_hidden': false,
      'start_date': '2026-03-21',
      'start_time': '09:00:00',
      'weekday_mask': null,
      'end_date': '2026-03-21',
      'end_time': '18:00:00',
      'alarm_offset_minutes': null,
      'completed_at': null,
      'created_at': '2026-03-19T11:00:00.000',
      'updated_at': '2026-03-20T08:45:00.000',
    },
    {
      'id': 'todo-3',
      'project': 'project-widget',
      'title': '선택 날짜를 위젯 데이터에 반영',
      'status': 'done',
      'kind': 'schedule',
      'version': 2,
      'created_by': _owner,
      'assignees': [_owner],
      'is_recurring': false,
      'is_hidden': false,
      'start_date': '2026-03-20',
      'start_time': '07:30:00',
      'weekday_mask': null,
      'end_date': '2026-03-20',
      'end_time': '08:00:00',
      'alarm_offset_minutes': null,
      'completed_at': '2026-03-20T07:40:00.000',
      'created_at': '2026-03-18T14:00:00.000',
      'updated_at': '2026-03-20T07:40:00.000',
    },
    {
      'id': 'todo-4',
      'project': 'project-widget',
      'title': 'ScheduleFragment에서 홈 위젯 버튼 연동',
      'status': 'todo',
      'kind': 'schedule',
      'version': 1,
      'created_by': _owner,
      'assignees': [_owner],
      'is_recurring': false,
      'is_hidden': false,
      'start_date': '2026-03-22',
      'start_time': '10:00:00',
      'weekday_mask': null,
      'end_date': '2026-03-22',
      'end_time': '12:00:00',
      'alarm_offset_minutes': null,
      'completed_at': null,
      'created_at': '2026-03-18T16:00:00.000',
      'updated_at': '2026-03-20T08:50:00.000',
    },
  ];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final method = options.method.toUpperCase();
    final segments = path.split('/').where((item) => item.isNotEmpty).toList();

    if (method == 'POST' && path.endsWith('/auth/mock-login/')) {
      return _jsonResponse({
        'id': 1,
        'email': _owner['email'],
        'nickname': _owner['nickname'],
        'access_token': 'demo-token',
      });
    }

    if (method == 'POST' && path.endsWith('/projects/sync/')) {
      return _jsonResponse({'projects': _projects});
    }

    if (method == 'POST' && path.endsWith('/todos/sync/')) {
      return _jsonResponse({'todos': _todos});
    }

    if (method == 'GET' && path.endsWith('/users/search/')) {
      final query = (options.queryParameters['q'] as String? ?? '')
          .trim()
          .toLowerCase();
      final limit =
          int.tryParse('${options.queryParameters['limit'] ?? '10'}') ?? 10;
      final filtered = _users
          .where((user) {
            if (query.isEmpty) {
              return true;
            }
            final email = '${user['email']}'.toLowerCase();
            final nickname = '${user['nickname']}'.toLowerCase();
            return email.contains(query) || nickname.contains(query);
          })
          .take(limit)
          .toList(growable: false);
      return _jsonResponse(filtered);
    }

    if (method == 'POST' && path.endsWith('/projects/')) {
      final body = _bodyAsMap(options);
      final now = DateTime.now().toIso8601String();
      final nextProject = {
        'id': 'project-${DateTime.now().microsecondsSinceEpoch}',
        'name': (body['name'] as String? ?? '').trim(),
        'description': (body['description'] as String? ?? '').trim(),
        'version': 1,
        'owner': _owner,
        'membership': [
          {'user': _owner, 'role': 'owner'},
        ],
        'recent_update_at': now,
        'created_at': now,
        'updated_at': now,
      };
      _projects.add(nextProject);
      return _jsonResponse(nextProject);
    }

    if (method == 'PATCH' &&
        segments.length == 2 &&
        segments.first == 'projects') {
      final projectId = segments[1];
      final body = _bodyAsMap(options);
      final index = _projects.indexWhere((item) => item['id'] == projectId);
      if (index == -1) {
        return _jsonResponse({'message': 'not_found'}, statusCode: 404);
      }
      final current = Map<String, dynamic>.from(_projects[index]);
      if (body.containsKey('name')) {
        current['name'] = body['name'];
      }
      if (body.containsKey('description')) {
        current['description'] = body['description'] ?? '';
      }
      current['version'] = (current['version'] as int? ?? 1) + 1;
      current['updated_at'] = DateTime.now().toIso8601String();
      current['recent_update_at'] = current['updated_at'];
      _projects[index] = current;
      return _jsonResponse(current);
    }

    if (method == 'DELETE' &&
        segments.length == 2 &&
        segments.first == 'projects') {
      final projectId = segments[1];
      _projects.removeWhere((item) => item['id'] == projectId);
      _todos.removeWhere((item) => item['project'] == projectId);
      return _jsonResponse({});
    }

    if (method == 'POST' &&
        segments.length == 3 &&
        segments.first == 'projects' &&
        segments[2] == 'invites') {
      final projectId = segments[1];
      final body = _bodyAsMap(options);
      final userId = body['user_id'] as int?;
      final role = (body['role'] as String? ?? 'writer').trim();
      final projectIndex = _projects.indexWhere(
        (item) => item['id'] == projectId,
      );
      if (projectIndex == -1 || userId == null) {
        return _jsonResponse({'message': 'not_found'}, statusCode: 404);
      }
      final user = _findUser(userId);
      if (user == null) {
        return _jsonResponse({'message': 'not_found'}, statusCode: 404);
      }
      final project = Map<String, dynamic>.from(_projects[projectIndex]);
      final membership = List<Map<String, dynamic>>.from(
        (project['membership'] as List<dynamic>).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      final exists = membership.any((item) {
        final memberUser = item['user'] as Map<String, dynamic>;
        return memberUser['id'] == userId;
      });
      if (!exists) {
        membership.add({'user': user, 'role': role});
      }
      project['membership'] = membership;
      project['version'] = (project['version'] as int? ?? 1) + 1;
      project['updated_at'] = DateTime.now().toIso8601String();
      project['recent_update_at'] = project['updated_at'];
      _projects[projectIndex] = project;
      return _jsonResponse({});
    }

    if (method == 'POST' && path.endsWith('/todos/')) {
      final body = _bodyAsMap(options);
      final projectId = body['project'] as String?;
      if (projectId == null ||
          !_projects.any((item) => item['id'] == projectId)) {
        return _jsonResponse({'message': 'not_found'}, statusCode: 404);
      }
      final assignees = _resolveUsers(body['assignees']);
      final status = (body['status'] as String? ?? 'todo').trim();
      final now = DateTime.now().toIso8601String();
      final nextTodo = {
        'id': 'todo-${DateTime.now().microsecondsSinceEpoch}',
        'project': projectId,
        'title': (body['title'] as String? ?? '').trim(),
        'status': status,
        'kind': (body['kind'] as String? ?? 'schedule').trim(),
        'version': 1,
        'created_by': _owner,
        'assignees': assignees,
        'is_recurring': body['is_recurring'] as bool? ?? false,
        'is_hidden': body['is_hidden'] as bool? ?? false,
        'start_date': body['start_date'],
        'start_time': body['start_time'],
        'weekday_mask': body['weekday_mask'],
        'end_date': body['end_date'],
        'end_time': body['end_time'],
        'alarm_offset_minutes': body['alarm_offset_minutes'],
        'completed_at': status == 'done' ? now : null,
        'created_at': now,
        'updated_at': now,
      };
      _todos.add(nextTodo);
      return _jsonResponse(nextTodo);
    }

    if (method == 'PATCH' &&
        segments.length == 2 &&
        segments.first == 'todos') {
      final todoId = segments[1];
      final body = _bodyAsMap(options);
      final index = _todos.indexWhere((item) => item['id'] == todoId);
      if (index == -1) {
        return _jsonResponse({'message': 'not_found'}, statusCode: 404);
      }

      final current = Map<String, dynamic>.from(_todos[index]);
      const allowedKeys = <String>{
        'project',
        'title',
        'status',
        'kind',
        'is_recurring',
        'is_hidden',
        'start_date',
        'start_time',
        'weekday_mask',
        'end_date',
        'end_time',
        'alarm_offset_minutes',
      };
      for (final entry in body.entries) {
        if (entry.key == 'assignees') {
          current['assignees'] = _resolveUsers(entry.value);
          continue;
        }
        if (allowedKeys.contains(entry.key)) {
          current[entry.key] = entry.value;
        }
      }

      if (body.containsKey('status')) {
        current['completed_at'] = current['status'] == 'done'
            ? DateTime.now().toIso8601String()
            : null;
      }
      current['version'] = (current['version'] as int? ?? 1) + 1;
      current['updated_at'] = DateTime.now().toIso8601String();
      _todos[index] = current;
      return _jsonResponse(current);
    }

    if (method == 'DELETE' &&
        segments.length == 2 &&
        segments.first == 'todos') {
      final todoId = segments[1];
      _todos.removeWhere((item) => item['id'] == todoId);
      return _jsonResponse({});
    }

    return _jsonResponse({'message': 'not_found'}, statusCode: 404);
  }

  Map<String, dynamic> _bodyAsMap(RequestOptions options) {
    return options.data is Map<String, dynamic>
        ? options.data as Map<String, dynamic>
        : <String, dynamic>{};
  }

  List<Map<String, dynamic>> _resolveUsers(Object? raw) {
    final values = raw is List ? raw : const [];
    return values
        .map(
          (value) => _findUser(value is int ? value : int.tryParse('$value')),
        )
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Map<String, dynamic>? _findUser(int? userId) {
    if (userId == null) {
      return null;
    }
    try {
      return Map<String, dynamic>.from(
        _users.firstWhere((user) => user['id'] == userId),
      );
    } catch (_) {
      return null;
    }
  }

  ResponseBody _jsonResponse(Object data, {int statusCode = 200}) {
    return ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
