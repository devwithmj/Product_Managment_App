import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_app/screens/print_preview_screen.dart';
import 'dart:typed_data';

void main() {
  group('PrintPreviewScreen Tests', () {
    testWidgets('should display back button in app bar', (
      WidgetTester tester,
    ) async {
      // Create sample PDF data
      final sampleData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: PrintPreviewScreen(pdfBytes: sampleData, title: 'Test Preview'),
        ),
      );

      // Verify app bar back button exists
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Test Preview'), findsOneWidget);
    });

    testWidgets('should display floating action buttons', (
      WidgetTester tester,
    ) async {
      // Create sample PDF data
      final sampleData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: PrintPreviewScreen(pdfBytes: sampleData, title: 'Test Preview'),
        ),
      );

      // Verify floating action buttons exist
      expect(find.byType(FloatingActionButton), findsWidgets);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('should call onBack when back button is pressed', (
      WidgetTester tester,
    ) async {
      // Create sample PDF data
      final sampleData = Uint8List.fromList([1, 2, 3, 4, 5]);
      bool onBackCalled = false;

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: PrintPreviewScreen(
            pdfBytes: sampleData,
            title: 'Test Preview',
            onBack: () {
              onBackCalled = true;
            },
          ),
        ),
      );

      // Tap the back button in app bar
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify onBack was called
      expect(onBackCalled, true);
    });

    testWidgets('should have print and share action buttons', (
      WidgetTester tester,
    ) async {
      // Create sample PDF data
      final sampleData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: PrintPreviewScreen(pdfBytes: sampleData, title: 'Test Preview'),
        ),
      );

      // Look for action buttons in app bar
      expect(find.byIcon(Icons.print), findsWidgets);
      expect(find.byIcon(Icons.share), findsWidgets);
    });
  });

  group('PrintPreviewHelper Tests', () {
    testWidgets('showPreview should navigate to preview screen', (
      WidgetTester tester,
    ) async {
      // Create sample PDF data
      final sampleData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Build a test app
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await PrintPreviewHelper.showPreview(
                        context: context,
                        pdfBytes: sampleData,
                        title: 'Test Title',
                      );
                    },
                    child: Text('Open Preview'),
                  ),
                ),
          ),
        ),
      );

      // Tap the button to open preview
      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byType(PrintPreviewScreen), findsOneWidget);
    });
  });
}
