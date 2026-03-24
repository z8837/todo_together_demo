import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'core/data/local/local_db.dart';
import 'features/schedule/application/home_widget/schedule_home_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDB.init();
  await ScheduleHomeWidgetService.initialize();
  runApp(bootstrapApp());
}
