extension TrStringExtension on String {
  String tr({Map<String, String>? namedArgs}) {
    const fallbackTranslations = <String, String>{
      'confirm': '확인',
      'cancel': '취소',
    };

    var value = fallbackTranslations[this] ?? this;
    final args = namedArgs;
    if (args == null || args.isEmpty) {
      return value;
    }
    args.forEach((key, replacement) {
      value = value.replaceAll('{$key}', replacement);
    });
    return value;
  }
}
