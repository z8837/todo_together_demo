import 'package:flutter/widgets.dart';

class AppBreakpoints {
  const AppBreakpoints._();

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1000;

  static bool useNavigationRail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 960;

  static bool useExtendedRail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1320;
}
