import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import '../models/product.dart';
import '../models/label_template.dart';

enum ThermalConnectionType { bluetooth, network }

class ThermalPrintService {
  static final FlutterThermalPrinter _thermalPrinter =
      FlutterThermalPrinter.instance;

  // Available printers list
  static final List<Map<String, String>> _availablePrinters = [];
  static dynamic _selectedPrinter;
  static bool _isConnected = false;

  // Get available printers - simplified implementation with manual setup
  static Future<List<Map<String, String>>> getAvailablePrinters({
    ThermalConnectionType type = ThermalConnectionType.bluetooth,
  }) async {
    try {
      // For now, return common TSP100III configurations
      // Users can manually add their printer's specific address
      if (type == ThermalConnectionType.bluetooth) {
        return [
          {
            'name': 'TSP100III Bluetooth',
            'address': 'Please scan or enter MAC address',
            'type': 'bluetooth',
          },
        ];
      } else {
        return [
          {
            'name': 'TSP100III Network',
            'address': 'Please enter IP address',
            'type': 'network',
          },
        ];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available printers: $e');
      }
      return [];
    }
  }

  // Manual printer connection (for when automatic discovery fails)
  static Future<bool> connectToManualAddress({
    required String address,
    required ThermalConnectionType type,
    String? name,
  }) async {
    try {
      final printerMap = {
        'address': address,
        'name': name ?? 'Manual Printer',
        'type': type.toString(),
      };

      _selectedPrinter = printerMap;
      final result = await _thermalPrinter.connect(_selectedPrinter);
      _isConnected = result == true;

      if (kDebugMode) {
        print('Manual connection to $address - Result: $result');
      }

      return _isConnected;
    } catch (e) {
      if (kDebugMode) {
        print('Error connecting to manual address: $e');
      }
      _isConnected = false;
      return false;
    }
  }

  // Connect to a specific printer
  static Future<bool> connectToPrinter(dynamic printer) async {
    try {
      _selectedPrinter = printer;
      final result = await _thermalPrinter.connect(printer);
      _isConnected = result == true;

      if (kDebugMode) {
        print('Connected to printer: ${printer.toString()} - Result: $result');
      }

      return _isConnected;
    } catch (e) {
      if (kDebugMode) {
        print('Error connecting to printer: $e');
      }
      _isConnected = false;
      return false;
    }
  }

  // Disconnect from printer
  static Future<void> disconnect() async {
    try {
      if (_selectedPrinter != null) {
        await _thermalPrinter.disconnect(_selectedPrinter);
      }
      _isConnected = false;
      _selectedPrinter = null;

      if (kDebugMode) {
        print('Disconnected from printer');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disconnecting from printer: $e');
      }
    }
  }

  // Check connection status
  static bool get isConnected => _isConnected;
  static dynamic get selectedPrinter => _selectedPrinter;
  static List<Map<String, String>> get availablePrinters => _availablePrinters;

  // Print single product label
  static Future<bool> printSingleLabel(
    Product product,
    LabelSize labelSize,
  ) async {
    if (!_isConnected || _selectedPrinter == null) {
      throw Exception('Printer not connected');
    }

    try {
      // Generate ESC/POS commands for the label
      final commands = _generateLabelCommands(product, labelSize);

      // Send to printer
      await _thermalPrinter.printData(_selectedPrinter, commands);

      if (kDebugMode) {
        print('Single label printed successfully for: ${product.fullNameEn}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error printing single label: $e');
      }
      return false;
    }
  }

  // Print multiple labels
  static Future<bool> printMultipleLabels(
    List<Product> products,
    LabelSize labelSize,
  ) async {
    if (!_isConnected || _selectedPrinter == null) {
      throw Exception('Printer not connected');
    }

    try {
      for (final product in products) {
        final commands = _generateLabelCommands(product, labelSize);
        await _thermalPrinter.printData(_selectedPrinter, commands);

        // Small delay between labels to prevent buffer overflow
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (kDebugMode) {
        print('${products.length} labels printed successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error printing multiple labels: $e');
      }
      return false;
    }
  }

  // Generate ESC/POS commands for a single label (TSP100III compatible)
  static Uint8List _generateLabelCommands(
    Product product,
    LabelSize labelSize,
  ) {
    final commands = <int>[];

    // Initialize printer
    commands.addAll([27, 64]); // ESC @

    // Set line spacing to tight
    commands.addAll([27, 51, 20]); // ESC 3 n (set line spacing to 20/180 inch)

    // Persian product name (Bold, Large)
    if (product.nameFa.isNotEmpty) {
      commands.addAll([27, 69, 1]); // ESC E 1 (bold on)
      commands.addAll([29, 33, 17]); // GS ! 17 (double height and width)
      commands.addAll([27, 97, 1]); // ESC a 1 (center align)

      // Convert Persian text to bytes (UTF-8)
      final persianBytes = utf8.encode(product.nameFa);
      commands.addAll(persianBytes);
      commands.addAll([10]); // LF (line feed)

      commands.addAll([27, 69, 0]); // ESC E 0 (bold off)
      commands.addAll([29, 33, 0]); // GS ! 0 (normal size)
    }

    // Brand name in Persian (if different from product name)
    if (product.brandFa.isNotEmpty && product.brandFa != product.nameFa) {
      commands.addAll([27, 97, 1]); // ESC a 1 (center align)
      final brandBytes = utf8.encode(product.brandFa);
      commands.addAll(brandBytes);
      commands.addAll([10]); // LF
    }

    // English product name
    if (product.nameEn.isNotEmpty) {
      commands.addAll([27, 97, 1]); // ESC a 1 (center align)
      commands.addAll([29, 33, 1]); // GS ! 1 (double width)

      final englishBytes = utf8.encode(product.fullNameEn);
      commands.addAll(englishBytes);
      commands.addAll([10, 10]); // LF LF (extra line)

      commands.addAll([29, 33, 0]); // GS ! 0 (normal size)
    }

    // Price (Bold, Large)
    commands.addAll([27, 69, 1]); // ESC E 1 (bold on)
    commands.addAll([29, 33, 17]); // GS ! 17 (double height and width)
    commands.addAll([27, 97, 1]); // ESC a 1 (center align)

    final priceText = '\$${product.price.toStringAsFixed(2)}';
    final priceBytes = utf8.encode(priceText);
    commands.addAll(priceBytes);
    commands.addAll([10]); // LF

    commands.addAll([27, 69, 0]); // ESC E 0 (bold off)
    commands.addAll([29, 33, 0]); // GS ! 0 (normal size)

    // Add some spacing and cut (TSP100III compatible)
    commands.addAll([10, 10, 10]); // LF LF LF (spacing)
    commands.addAll([29, 86, 65, 3]); // GS V A 3 (full cut)

    return Uint8List.fromList(commands);
  }

  // Test printer connection with a simple print
  static Future<bool> testPrint() async {
    if (!_isConnected || _selectedPrinter == null) {
      throw Exception('Printer not connected');
    }

    try {
      final commands = <int>[];

      // Initialize printer
      commands.addAll([27, 64]); // ESC @

      // Test message
      commands.addAll([27, 97, 1]); // ESC a 1 (center align)
      commands.addAll([27, 69, 1]); // ESC E 1 (bold on)

      final testMessage =
          'TSP100III Test Print\nConnection Successful\nThermal Printer Ready';
      final messageBytes = utf8.encode(testMessage);
      commands.addAll(messageBytes);
      commands.addAll([10, 10, 10]); // LF LF LF

      commands.addAll([27, 69, 0]); // ESC E 0 (bold off)
      commands.addAll([29, 86, 65, 3]); // GS V A 3 (full cut)

      await _thermalPrinter.printData(
        _selectedPrinter,
        Uint8List.fromList(commands),
      );

      if (kDebugMode) {
        print('Test print successful');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Test print failed: $e');
      }
      return false;
    }
  }

  // Get printer status
  static Future<PrinterStatus> getPrinterStatus() async {
    if (!_isConnected || _selectedPrinter == null) {
      return PrinterStatus.disconnected;
    }

    try {
      // Check if still connected
      return _isConnected ? PrinterStatus.ready : PrinterStatus.disconnected;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting printer status: $e');
      }
      return PrinterStatus.error;
    }
  }

  // Helper method to get printer name for display
  static String getPrinterDisplayName(dynamic printer) {
    try {
      if (printer is Map) {
        return printer['name'] ?? printer['address'] ?? 'Unknown Printer';
      }
      return printer.toString();
    } catch (e) {
      return 'Unknown Printer';
    }
  }

  // Helper method to get printer address for connection
  static String getPrinterAddress(dynamic printer) {
    try {
      if (printer is Map) {
        return printer['address'] ?? '';
      }
      return printer.toString();
    } catch (e) {
      return '';
    }
  }
}

enum PrinterStatus { ready, busy, error, disconnected, paperOut }
