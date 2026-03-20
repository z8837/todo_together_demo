import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Widget bootstrapApp() {
  return const ProviderScope(child: TodoTogetherDemoApp());
}
