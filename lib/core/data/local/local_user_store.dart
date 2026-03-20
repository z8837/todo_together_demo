import 'package:isar_community/isar.dart';

import 'package:todotogether/core/data/local/entities/local_user_entity.dart';
import 'package:todotogether/core/data/local/local_db.dart';
import 'package:todotogether/core/data/models/user_dto.dart';

class LocalUserStore {
  LocalUserStore({Isar? isar}) : _isar = isar ?? LocalDB.instance;

  final Isar _isar;

  Future<List<int>> findUserIdsMissingProfile({int limit = 50}) async {
    final users = await _isar.localUserEntitys.where().findAll();
    final missing = <int>[];
    for (final user in users) {
      if (user.remoteId <= 0) {
        continue;
      }
      if (user.email.trim().isEmpty || user.nickname.trim().isEmpty) {
        missing.add(user.remoteId);
        if (missing.length >= limit) {
          break;
        }
      }
    }
    return missing;
  }

  Future<void> upsertUser(UserDto dto) async {
    final existing = await _isar.localUserEntitys
        .where()
        .remoteIdEqualTo(dto.id)
        .findFirst();

    final resolvedEmail = dto.email.trim().isEmpty
        ? (existing?.email ?? '')
        : dto.email;
    final resolvedNickname = dto.nickname.trim().isEmpty
        ? (existing?.nickname ?? '')
        : dto.nickname;
    final normalizedProvider = dto.provider?.trim();
    final resolvedProvider =
        (normalizedProvider == null || normalizedProvider.isEmpty)
        ? existing?.provider
        : normalizedProvider;

    if (existing == null) {
      final entity = LocalUserEntity()
        ..remoteId = dto.id
        ..email = resolvedEmail
        ..nickname = resolvedNickname
        ..provider = resolvedProvider
        ..updatedAt = DateTime.now();
      await _isar.localUserEntitys.putByRemoteId(entity);
      return;
    }

    existing
      ..email = resolvedEmail
      ..nickname = resolvedNickname
      ..provider = resolvedProvider
      ..updatedAt = DateTime.now();
    await _isar.localUserEntitys.put(existing);
  }

  Future<void> upsertUsers(Iterable<UserDto> users) async {
    if (users.isEmpty) {
      return;
    }
    await _isar.writeTxn(() async {
      for (final user in users) {
        await upsertUser(user);
      }
    });
  }

  Future<Map<int, LocalUserEntity>> loadUsersByIds(
    Iterable<int> userIds,
  ) async {
    final ids = userIds.toSet().toList();
    if (ids.isEmpty) {
      return const {};
    }
    final results = await _isar.localUserEntitys
        .where()
        .anyOf(ids, (q, id) => q.remoteIdEqualTo(id))
        .findAll();
    return {for (final user in results) user.remoteId: user};
  }

  Future<void> updateUserProfile({
    required int userId,
    String? nickname,
    String? email,
    String? provider,
  }) async {
    final normalizedNickname = nickname?.trim();
    final normalizedEmail = email?.trim();
    final normalizedProvider = provider?.trim();
    await _isar.writeTxn(() async {
      final existing = await _isar.localUserEntitys
          .where()
          .remoteIdEqualTo(userId)
          .findFirst();
      if (existing == null) {
        if ((normalizedNickname == null || normalizedNickname.isEmpty) &&
            (normalizedEmail == null || normalizedEmail.isEmpty) &&
            (normalizedProvider == null || normalizedProvider.isEmpty)) {
          return;
        }
        final entity = LocalUserEntity()
          ..remoteId = userId
          ..nickname = normalizedNickname ?? ''
          ..email = normalizedEmail ?? ''
          ..provider = normalizedProvider
          ..updatedAt = DateTime.now();
        await _isar.localUserEntitys.putByRemoteId(entity);
        return;
      }
      existing
        ..nickname = (normalizedNickname == null || normalizedNickname.isEmpty)
            ? existing.nickname
            : normalizedNickname
        ..email = (normalizedEmail == null || normalizedEmail.isEmpty)
            ? existing.email
            : normalizedEmail
        ..provider = (normalizedProvider == null || normalizedProvider.isEmpty)
            ? existing.provider
            : normalizedProvider
        ..updatedAt = DateTime.now();
      await _isar.localUserEntitys.put(existing);
    });
  }
}
