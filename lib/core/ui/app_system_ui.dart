import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSystemUi {
  const AppSystemUi._();

  static const mainSurface = Color(0xFFFCFDFF);
  static const mainBackground = Color(0xFFFFFFFF);
  static const outline = Color(0xFFF1F1F1);
  static const divider = Color(0xFFE6E6E6);

  static const mainOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: mainSurface,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
}
