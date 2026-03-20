import 'package:flutter/material.dart';

class ProjectColorResolver {
  static const List<Color> _palette = <Color>[
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
    Colors.cyan,
    Colors.purple,
    Colors.blueGrey,
    Colors.green,
    Colors.pink,
    Colors.amber,
  ];

  static Color resolve(String id) {
    if (id.isEmpty) {
      return _palette.first;
    }
    final hash = id.codeUnits.fold<int>(0, (value, element) => value + element);
    return _palette[hash.abs() % _palette.length];
  }
}
