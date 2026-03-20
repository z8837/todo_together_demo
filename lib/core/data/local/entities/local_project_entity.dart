import 'package:isar_community/isar.dart';

part 'local_project_entity.g.dart';

@collection
class LocalProjectEntity {
  LocalProjectEntity();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  String name = '';
  String description = '';
  int version = 1;
  int? ownerUserId;
  DateTime? recentUpdateAt;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  List<LocalProjectMemberEmbedded> members = [];
}

@embedded
class LocalProjectMemberEmbedded {
  LocalProjectMemberEmbedded();

  late int userId;
  String role = 'reader';
}
