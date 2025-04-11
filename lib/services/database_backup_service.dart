import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

import '../models/product.dart';
import 'database_service.dart';

class DatabaseBackupService {
  final DatabaseService _databaseService = DatabaseService();

  // Export database to a JSON file
  Future<String?> exportDatabase() async {
    try {
      // Get all products from the database
      final products = await _databaseService.getProducts();

      if (products.isEmpty) {
        return 'No products to export';
      }

      // Convert to a JSON string
      final productsJson = products.map((product) => product.toMap()).toList();
      final jsonString = jsonEncode(productsJson);

      // Create a file in the documents directory
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'product_labels_backup_$timestamp.json';

      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);

      // Write data to the file
      final file = File(filePath);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      print('Error exporting database: $e');
      return null;
    }
  }

  // Share the database export file
  Future<void> shareExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'Product Labels Database Backup');
      }
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  // Import database from a JSON file
  Future<String> importDatabase() async {
    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          return 'Storage permission denied';
        }
      }

      // Pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return 'No file selected';
      }

      final file = File(result.files.first.path!);
      if (!await file.exists()) {
        return 'File does not exist';
      }

      // Read the file content
      final jsonString = await file.readAsString();

      // Parse the JSON
      List<dynamic> jsonList;
      try {
        jsonList = jsonDecode(jsonString);
      } catch (e) {
        return 'Invalid JSON format';
      }

      // Convert JSON to products
      List<Product> products = [];
      try {
        products = jsonList.map((json) => Product.fromMap(json)).toList();
      } catch (e) {
        return 'Invalid product format in JSON file';
      }

      if (products.isEmpty) {
        return 'No products found in file';
      }

      // Ask for user confirmation
      final importType = await _showImportOptions();
      if (importType == null) {
        return 'Import cancelled';
      }

      // Perform the import based on user selection
      if (importType == ImportType.replace) {
        // Delete all existing products
        await _databaseService.deleteAllProducts();
      }

      // Add the imported products
      int importedCount = 0;
      for (final product in products) {
        try {
          await _databaseService.saveProduct(product);
          importedCount++;
        } catch (e) {
          print('Error importing product: $e');
        }
      }

      return 'Successfully imported $importedCount products';
    } catch (e) {
      print('Error importing database: $e');
      return 'Error: $e';
    }
  }

  // Show import options dialog
  Future<ImportType?> _showImportOptions() async {
    return await showDialog<ImportType>(
      context: navigatorKey.currentContext!,
      builder:
          (context) => AlertDialog(
            title: const Text('Import Options'),
            content: const Text(
              'How would you like to import products?\n\n'
              'Replace: Delete all existing products and replace with imported ones.\n\n'
              'Merge: Keep existing products and add the imported ones.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImportType.merge),
                child: const Text('Merge'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImportType.replace),
                child: const Text('Replace'),
              ),
            ],
          ),
    );
  }
}

// Navigator key to access context from outside of widget
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Import types
enum ImportType { merge, replace }
