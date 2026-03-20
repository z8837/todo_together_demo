import 'package:flutter/material.dart';

class AppInsets {
  static const EdgeInsets screen = EdgeInsets.fromLTRB(20, 12, 20, 24);
  static const EdgeInsets screenTop24 = EdgeInsets.fromLTRB(20, 24, 20, 24);
  static const EdgeInsets screenTop8 = EdgeInsets.fromLTRB(20, 8, 20, 24);
  static const EdgeInsets screenTop0 = EdgeInsets.fromLTRB(20, 0, 20, 24);
  static const EdgeInsets dialog = EdgeInsets.fromLTRB(23, 21, 23, 19);

  static const EdgeInsets v12 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets h32 = EdgeInsets.symmetric(horizontal: 32);
  static const EdgeInsets h24 = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets h18v14 = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 14,
  );
  static const EdgeInsets h14v12 = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );
  static const EdgeInsets h14v14 = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 14,
  );
  static const EdgeInsets h6v6 = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 6,
  );

  static const EdgeInsets all14 = EdgeInsets.all(14);
  static const EdgeInsets all16 = EdgeInsets.all(16);
  static const EdgeInsets right5 = EdgeInsets.only(right: 5.0);
  static const EdgeInsets page = EdgeInsets.fromLTRB(20, 16, 20, 20);
}

class AppGap {
  static const Widget h2 = SizedBox(height: 2);
  static const Widget h3 = SizedBox(height: 3);
  static const Widget h4 = SizedBox(height: 4);
  static const Widget h6 = SizedBox(height: 6);
  static const Widget h8 = SizedBox(height: 8);
  static const Widget h10 = SizedBox(height: 10);
  static const Widget h12 = SizedBox(height: 12);
  static const Widget h14 = SizedBox(height: 14);
  static const Widget h16 = SizedBox(height: 16);
  static const Widget h20 = SizedBox(height: 20);
  static const Widget h24 = SizedBox(height: 24);

  static const Widget w4 = SizedBox(width: 4);
  static const Widget w6 = SizedBox(width: 6);
  static const Widget w8 = SizedBox(width: 8);
  static const Widget w10 = SizedBox(width: 10);
  static const Widget w12 = SizedBox(width: 12);
  static const Widget w16 = SizedBox(width: 16);
}
