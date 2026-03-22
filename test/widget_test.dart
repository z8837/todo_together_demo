import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotogether/core/widgets/section_card.dart';
import 'package:todotogether/features/auth/presentation/pages/login_screen.dart';

void main() {
  testWidgets('로그인 화면의 기본 구조가 보인다', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(find.byType(SectionCard), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
