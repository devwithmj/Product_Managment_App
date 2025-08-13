import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:product_app/services/csv_import_service.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final CsvImportService _importService = CsvImportService();

  File? _selectedFile;
  bool _isImporting = false;
  CsvImportResult? _importResult;
  String? _validationMessage;
  int _validatedRows = 0;
  bool _isValidFile = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Price from CSV'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CSV Format Instructions',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your CSV file should contain at least three columns in this order:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'barcode,price,name,date\n'
                        '"00000005660106",2.990,CRUSH,2025-07-31\n'
                        '"00000001234567",15.50,Another Product,2025-08-01',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Leading zeros in barcodes will be automatically removed\n'
                      '• If barcode exists: Updates product price\n'
                      '• If barcode is new: Creates product with default values (marked as auto-generated)\n'
                      '• Date column is optional and will be ignored',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // File Selection
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _selectFile,
              icon: const Icon(Icons.file_upload),
              label: Text(
                _selectedFile == null ? 'Select CSV File' : 'Change File',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            if (_selectedFile != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFile!.path.split('/').last,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_validationMessage != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _isValidFile ? Icons.check_circle : Icons.error,
                              size: 16,
                              color: _isValidFile ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _validationMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      _isValidFile ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_isValidFile && _validatedRows > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Ready to import $_validatedRows rows',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Import Button
            ElevatedButton.icon(
              onPressed:
                  (_selectedFile != null && _isValidFile && !_isImporting)
                      ? _importCsv
                      : null,
              icon:
                  _isImporting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.upload),
              label: Text(_isImporting ? 'Importing...' : 'Import CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // Import Results
            if (_importResult != null) ...[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _importResult!.hasErrors
                                  ? Icons.warning
                                  : Icons.check_circle,
                              color:
                                  _importResult!.hasErrors
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Import Results',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Summary Statistics
                        _buildStatRow(
                          'Total Rows Processed',
                          '${_importResult!.totalRows}',
                        ),
                        _buildStatRow(
                          'Products Updated',
                          '${_importResult!.updatedProducts}',
                          Colors.blue,
                        ),
                        _buildStatRow(
                          'Products Created',
                          '${_importResult!.createdProducts}',
                          Colors.green,
                        ),
                        if (_importResult!.errorRows > 0)
                          _buildStatRow(
                            'Errors',
                            '${_importResult!.errorRows}',
                            Colors.red,
                          ),

                        if (_importResult!
                            .autoGeneratedProducts
                            .isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Auto-Generated Products',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount:
                                  _importResult!.autoGeneratedProducts.length,
                              itemBuilder: (context, index) {
                                final product =
                                    _importResult!.autoGeneratedProducts[index];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                  ),
                                  title: Text(
                                    product.nameEn,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    'Barcode: ${product.barcode} • Price: \$${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: const Text(
                                    'Auto-generated',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        if (_importResult!.errors.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Errors',
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _importResult!.errors.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    _importResult!.errors[index],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _selectedFile = file;
          _importResult = null;
          _validationMessage = null;
          _isValidFile = false;
          _validatedRows = 0;
        });

        // Validate the file
        await _validateFile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _validateFile() async {
    if (_selectedFile == null) return;

    try {
      final validation = await _importService.validateCsvFile(_selectedFile!);
      setState(() {
        _isValidFile = validation.$1;
        _validationMessage = validation.$2;
        _validatedRows = validation.$3;
      });
    } catch (e) {
      setState(() {
        _isValidFile = false;
        _validationMessage = 'Error validating file: $e';
        _validatedRows = 0;
      });
    }
  }

  Future<void> _importCsv() async {
    if (_selectedFile == null) return;

    setState(() {
      _isImporting = true;
      _importResult = null;
    });

    try {
      final result = await _importService.importFromCsv(_selectedFile!);

      setState(() {
        _importResult = result;
        _isImporting = false;
      });

      // Show success message
      if (mounted) {
        final message =
            result.hasErrors
                ? 'Import completed with ${result.errorRows} errors. ${result.successfulRows} products processed.'
                : 'Import completed successfully! ${result.successfulRows} products processed.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: result.hasErrors ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
