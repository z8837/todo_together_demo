import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todotogether/features/auth/presentation/pages/login_screen.dart';

void main() {
  testWidgets('로그인 화면', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(find.text('Todo Together Demo 로그인'), findsOneWidget);
    expect(find.text('모의 로그인'), findsOneWidget);
    expect(find.textContaining('Riverpod 상태관리'), findsOneWidget);
    expect(find.textContaining('HomeWidget 연동 예시'), findsOneWidget);
  });
}
