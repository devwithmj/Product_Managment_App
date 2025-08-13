import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_app/services/csv_import_service.dart';

void main() {
  group('CSV Import Service Tests', () {
    late CsvImportService csvImportService;

    setUp(() {
      csvImportService = CsvImportService();
    });

    test('validateCsvFile should accept the new format', () async {
      // Create a temporary CSV file with the new format
      final tempDir = Directory.systemTemp;
      final csvFile = File('${tempDir.path}/test_prices.csv');

      const csvContent = '''f01,f30,F02,F2130
"00000005660106",2.990,CRUSH,2025-07-31 00:00:00.000
"00000001234567",15.50,Sample Product,2025-08-01 00:00:00.000''';

      await csvFile.writeAsString(csvContent);

      try {
        final result = await csvImportService.validateCsvFile(csvFile);

        expect(result.$1, isTrue, reason: 'CSV should be valid');
        expect(result.$3, equals(2), reason: 'Should detect 2 data rows');
        expect(
          result.$2,
          contains('valid'),
          reason: 'Should indicate file is valid',
        );
      } finally {
        // Clean up
        if (await csvFile.exists()) {
          await csvFile.delete();
        }
      }
    });

    test('validateCsvFile should reject invalid format', () async {
      // Create a temporary CSV file with invalid format
      final tempDir = Directory.systemTemp;
      final csvFile = File('${tempDir.path}/test_invalid.csv');

      const csvContent = '''invalid,format
just,one,column''';

      await csvFile.writeAsString(csvContent);

      try {
        final result = await csvImportService.validateCsvFile(csvFile);

        expect(result.$1, isFalse, reason: 'Invalid CSV should be rejected');
      } finally {
        // Clean up
        if (await csvFile.exists()) {
          await csvFile.delete();
        }
      }
    });

    test('validateCsvFile should handle empty file', () async {
      // Create a temporary empty CSV file
      final tempDir = Directory.systemTemp;
      final csvFile = File('${tempDir.path}/test_empty.csv');

      await csvFile.writeAsString('');

      try {
        final result = await csvImportService.validateCsvFile(csvFile);

        expect(result.$1, isFalse, reason: 'Empty CSV should be rejected');
        expect(
          result.$2,
          contains('empty'),
          reason: 'Should indicate file is empty',
        );
      } finally {
        // Clean up
        if (await csvFile.exists()) {
          await csvFile.delete();
        }
      }
    });
  });
}
