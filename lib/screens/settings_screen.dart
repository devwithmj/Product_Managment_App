import 'package:flutter/material.dart';
import '../services/database_backup_service.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseBackupService _backupService = DatabaseBackupService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  int _productCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProductCount();
  }

  Future<void> _loadProductCount() async {
    final products = await _databaseService.getProducts();
    setState(() {
      _productCount = products.length;
    });
  }

  Future<void> _exportDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final filePath = await _backupService.exportDatabase();

      if (filePath == null) {
        _showSnackBar('Failed to export database');
      } else if (filePath.startsWith('No products')) {
        _showSnackBar(filePath);
      } else {
        await _backupService.shareExportFile(filePath);
      }
    } catch (e) {
      _showSnackBar('Error exporting database: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _backupService.importDatabase();
      _showSnackBar(result);
      await _loadProductCount(); // Refresh product count
    } catch (e) {
      _showSnackBar('Error importing database: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Database section
                    Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Database',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text('Products: $_productCount'),
                            const SizedBox(height: 16.0),

                            // Export button
                            ElevatedButton.icon(
                              onPressed: _exportDatabase,
                              icon: const Icon(Icons.upload),
                              label: const Text('Export Database'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 40),
                              ),
                            ),
                            const SizedBox(height: 8.0),

                            // Import button
                            ElevatedButton.icon(
                              onPressed: _importDatabase,
                              icon: const Icon(Icons.download),
                              label: const Text('Import Database'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 40),
                                backgroundColor: Colors.green,
                              ),
                            ),

                            // Clear database button
                            const SizedBox(height: 16.0),
                            ElevatedButton.icon(
                              onPressed: () => _showClearDatabaseDialog(),
                              icon: const Icon(Icons.delete),
                              label: const Text('Clear Database'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 40),
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // App info section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'App Information',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            const Text('Version: 1.0.0'),
                            const SizedBox(height: 4.0),
                            const Text(
                              'Label Printing App for product price tags',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Future<void> _showClearDatabaseDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Database'),
          content: const Text(
            'Are you sure you want to delete all products? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete All',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _clearDatabase();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.deleteAllProducts();
      await _loadProductCount();
      _showSnackBar('Database cleared successfully');
    } catch (e) {
      _showSnackBar('Error clearing database: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
