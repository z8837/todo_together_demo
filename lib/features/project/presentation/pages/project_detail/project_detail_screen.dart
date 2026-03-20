import 'package:flutter/material.dart';

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.focusTodoId,
    this.embedded = false,
    this.onClose,
  });

  final String projectId;
  final String? focusTodoId;
  final bool embedded;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embedded ? null : AppBar(title: const Text('프로젝트 상세')),
      body: Center(
        child: Text('공개 데모에서는 프로젝트 상세 편집 화면을 생략했습니다.\nID: $projectId'),
      ),
    );
  }
}
