// Smoke tests for the Chat Toolkit demo app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('shows the seeded conversation', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요! 무엇을 도와드릴까요?'), findsOneWidget);
    expect(find.text('안녕하세요! 채팅 기능 테스트 중입니다.'), findsOneWidget);
  });

  testWidgets('long press opens a different menu per side', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Receiver bubble: long press.
    await tester.longPress(find.text('안녕하세요! 무엇을 도와드릴까요?'));
    await tester.pumpAndSettle();
    expect(find.text('답장'), findsOneWidget);
    expect(find.text('신고'), findsOneWidget);
    expect(find.text('삭제'), findsNothing);

    await tester.tapAt(const Offset(5, 5)); // dismiss
    await tester.pumpAndSettle();

    // Sender bubble: long press.
    await tester.longPress(find.text('안녕하세요! 채팅 기능 테스트 중입니다.'));
    await tester.pumpAndSettle();

    expect(find.text('삭제'), findsOneWidget);
    expect(find.text('재전송'), findsOneWidget);
    expect(find.text('답장'), findsNothing);
  });

  testWidgets('deletes a message from the sender menu', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('안녕하세요! 채팅 기능 테스트 중입니다.'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요! 채팅 기능 테스트 중입니다.'), findsNothing);
  });

  testWidgets('sends a message from the input field', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '테스트 메시지');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('테스트 메시지'), findsOneWidget);
  });
}
