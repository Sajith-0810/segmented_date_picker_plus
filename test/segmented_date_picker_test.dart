import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segmented_date_picker_plus/segmented_date_picker_plus.dart';

void main() {
  group('showSegmentedDatePicker Widget Tests', () {
    // Shared variable to capture the result of the dialog
    DateTime? pickedDate;

    // Helper function to mount the app and open the dialog
    Future<void> pumpAndOpenPicker(
      WidgetTester tester, {
      DateTime? initialDate,
      SegmentedPickerColors? colors,
    }) async {
      pickedDate = null; // Reset before each test
      final firstDate = DateTime(2000);
      final lastDate = DateTime(2100);
      final initDate = initialDate ?? DateTime(2026, 11, 13);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  pickedDate = await showSegmentedDatePicker(
                    context: context,
                    initialDate: initDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    pickerColors: colors,
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to open the dialog
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle(); // Wait for the entry animation
    }

    testWidgets('renders dialog and displays initial date correctly', (
      WidgetTester tester,
    ) async {
      await pumpAndOpenPicker(tester, initialDate: DateTime(2026, 11, 13));

      // Verify header text
      expect(find.text('Nov 13, 2026'), findsOneWidget); // Medium date format

      // Verify Segment buttons exist
      expect(find.text('YEAR'), findsOneWidget);
      expect(find.text('MONTH'), findsOneWidget);
      expect(find.text('DAY'), findsOneWidget);

      // Verify Action buttons exist
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
    });

    testWidgets('selects a new day and returns correct DateTime on OK', (
      WidgetTester tester,
    ) async {
      await pumpAndOpenPicker(tester, initialDate: DateTime(2026, 11, 13));

      // The day 20 should be visible in the current month grid
      final day20 = find.text('20');
      expect(day20, findsOneWidget);

      // Tap the 20th
      await tester.tap(day20);
      await tester
          .pumpAndSettle(); // Wait for state to update (selection styling)

      // Tap OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle(); // Wait for dialog exit animation

      // Verify the future returned the correct date
      expect(pickedDate, isNotNull);
      expect(pickedDate?.year, 2026);
      expect(pickedDate?.month, 11);
      expect(pickedDate?.day, 20);
    });

    testWidgets('returns null when CANCEL is tapped', (
      WidgetTester tester,
    ) async {
      await pumpAndOpenPicker(tester, initialDate: DateTime(2026, 11, 13));

      // Tap a different day just to change state
      await tester.tap(find.text('25'));
      await tester.pumpAndSettle();

      // Tap CANCEL
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      // Result should be null
      expect(pickedDate, isNull);
    });

    testWidgets('switches to Year panel when YEAR segment is tapped', (
      WidgetTester tester,
    ) async {
      await pumpAndOpenPicker(tester, initialDate: DateTime(2026, 11, 13));

      // Tap the YEAR segment
      // Note: Because the text 'YEAR' is inside a Semantics/InkWell, we find the closest button.
      await tester.tap(find.text('YEAR'));
      await tester.pumpAndSettle(); // Wait for panel transition

      // The grid should now show years instead of days.
      // We should find the year 2026 in the grid.
      // (Using findsWidgets because '2026' might also be in the header, we expect at least 2 now)
      expect(find.text('2026'), findsWidgets);
      expect(find.text('2027'), findsOneWidget);
    });

    testWidgets('switches to Input mode when edit icon is tapped', (
      WidgetTester tester,
    ) async {
      await pumpAndOpenPicker(tester, initialDate: DateTime(2026, 11, 13));

      // Find the input mode toggle icon (Icons.edit_calendar_outlined)
      final editIcon = find.byIcon(Icons.edit_calendar_outlined);
      expect(editIcon, findsOneWidget);

      // Tap it
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Should now see a TextFormField for manual date entry
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
