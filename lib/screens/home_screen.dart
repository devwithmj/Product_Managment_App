import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/database_service.dart';
import 'product_list_screen.dart';
import 'print_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const ProductListScreen(),
    const PrintScreen(),
  ];
  final DatabaseService _databaseService = DatabaseService();
  bool _isRepairing = false;

  @override
  void initState() {
    super.initState();
    _checkDatabaseAccess();
  }

  Future<void> _checkDatabaseAccess() async {
    try {
      bool isReadOnly = await _databaseService.isDatabaseReadOnly();
      if (isReadOnly) {
        // Use a post-frame callback to ensure the context is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showDatabaseErrorDialog();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking database access: $e');
      }
    }
  }

  void _showDatabaseErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Database Access Error'),
            content: const Text(
              'Your database appears to be in read-only mode. This can prevent you from adding or updating products. Would you like to repair it now?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Later'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _repairDatabase(fullRepair: true);
                },
                child: const Text('Repair Now'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appTitle),
        centerTitle: true,
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _screens[_currentIndex],
          if (_isRepairing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Repairing database...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.print),
            label: 'Print Labels',
          ),
        ],
      ),
    );
  }

  Future<void> _repairDatabase({bool fullRepair = false}) async {
    setState(() {
      _isRepairing = true;
    });

    try {
      // Reset the connection
      await _databaseService.resetDatabaseConnection();

      // If full repair requested or if we still have issues
      if (fullRepair || await _databaseService.isDatabaseReadOnly()) {
        if (kDebugMode) {
          print('Performing full database repair');
        }
        await _databaseService.recreateProductsTable();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database repair completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database repair failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRepairing = false;
        });
      }
    }
  }
}
