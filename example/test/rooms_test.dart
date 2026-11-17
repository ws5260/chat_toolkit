import 'package:example/main.dart';
import 'package:example/rooms/fake_chat_server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final reverse in [true, false]) {
    group('reverse: $reverse', () {
      Future<void> openRoom(WidgetTester tester, RoomInfo room) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const MyApp(home: AppHome.rooms));
        await tester.pumpAndSettle();
        if (!reverse) {
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(room.title));
        await tester.pump(); // route push
        await tester.pump(const Duration(milliseconds: 400));
      }

      ScrollPosition position(WidgetTester tester) => tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!
          .position;

      double gap(WidgetTester tester) => reverse
          ? position(tester).pixels
          : position(tester).maxScrollExtent - position(tester).pixels;

      String debugBar(WidgetTester tester) =>
          tester.widget<Text>(find.textContaining('onScrollToTop')).data!;

      // Lets the first page, late images and any older-page load finish.
      Future<void> settle(WidgetTester tester, RoomInfo room) async {
        await tester.pump(room.latency);
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pump(room.latency);
        await tester.pumpAndSettle();
      }

      for (final room in demoRooms) {
        testWidgets('${room.title}: opens at the bottom and stays there', (
          tester,
        ) async {
          await openRoom(tester, room);
          await settle(tester, room);

          expect(gap(tester), lessThanOrEqualTo(2));
          final fillsScreen = room.totalMessages > 10;
          if (fillsScreen) {
            // No older page loaded without the user scrolling up.
            expect(debugBar(tester), contains('onScrollToTop 0회'));
          }
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets(
        'scrolling to the oldest end loads one older page and keeps the view in place',
        (tester) async {
          final room = demoRooms.firstWhere((r) => r.id == 'long');
          await openRoom(tester, room);
          await settle(tester, room);
          expect(debugBar(tester), contains('로드 30/500건'));

          final p = position(tester);
          p.jumpTo(reverse ? p.maxScrollExtent : 0);
          await tester.pump();
          // The oldest loaded message (#470) is on screen at the older end.
          expect(find.textContaining('#470 '), findsOneWidget);
          await settle(tester, room);

          // Exactly one page, not a cascade of pages until everything is loaded.
          expect(debugBar(tester), contains('onScrollToTop 1회'));
          expect(debugBar(tester), contains('로드 60/500건'));
          // The view did not jump to the added messages.
          expect(find.textContaining('#470 '), findsOneWidget);
        },
      );
    });
  }
}
