import 'package:isar_community/isar.dart';

part 'local_user_entity.g.dart';

@collection
class LocalUserEntity {
  LocalUserEntity();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late int remoteId;

  String email = '';
  String nickname = '';
  String? provider;
  DateTime? updatedAt;
}
