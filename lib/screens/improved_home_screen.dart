import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/database_service.dart';
import 'dashboard_screen.dart';
import 'product_list_screen.dart';
import 'print_screen.dart';
import 'barcode_scanner_screen.dart';
import 'settings_screen.dart';

class ImprovedHomeScreen extends StatefulWidget {
  const ImprovedHomeScreen({super.key});

  @override
  _ImprovedHomeScreenState createState() => _ImprovedHomeScreenState();
}

class _ImprovedHomeScreenState extends State<ImprovedHomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final DatabaseService _databaseService = DatabaseService();
  bool _isRepairing = false;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductListScreen(),
    const PrintScreen(),
    const BarcodeScannerScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Products',
    'Print Labels',
    'Scan Barcode',
  ];

  @override
  void initState() {
    super.initState();
    _checkDatabaseAccess();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkDatabaseAccess() async {
    try {
      bool isReadOnly = await _databaseService.isDatabaseReadOnly();
      if (isReadOnly) {
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

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Quick scan button
          if (_currentIndex != 3) // Don't show on scanner screen
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Quick Scan',
              onPressed: () {
                setState(() {
                  _currentIndex = 3;
                });
                _pageController.animateToPage(
                  3,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          // Notification/Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'App Info',
            onPressed: () => _showAppInfo(),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _screens,
          ),
          if (_isRepairing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Repairing database...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.print), label: 'Print'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.inventory_2, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  AppStrings.appTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppFonts.englishFont,
                  ),
                ),
                Text(
                  'Product Management & Label Printing',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: AppFonts.englishFont,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () => _navigateFromDrawer(0),
          ),
          _buildDrawerItem(
            icon: Icons.inventory,
            title: 'Manage Products',
            onTap: () => _navigateFromDrawer(1),
          ),
          _buildDrawerItem(
            icon: Icons.print,
            title: 'Print Labels',
            onTap: () => _navigateFromDrawer(2),
          ),
          _buildDrawerItem(
            icon: Icons.qr_code_scanner,
            title: 'Barcode Scanner',
            onTap: () => _navigateFromDrawer(3),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () => _navigateToSettings(),
          ),
          _buildDrawerItem(
            icon: Icons.backup,
            title: 'Backup & Restore',
            onTap: () => _showBackupOptions(),
          ),
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => _showHelp(),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.build,
            title: 'Repair Database',
            onTap: () => _repairDatabase(fullRepair: true),
            textColor: Colors.orange,
          ),
          _buildDrawerItem(
            icon: Icons.info,
            title: 'About',
            onTap: () => _showAppInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(fontFamily: AppFonts.englishFont, color: textColor),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }

  void _navigateFromDrawer(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _showBackupOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Backup & Restore'),
            content: const Text(
              'Backup and restore functionality will be available here.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Help & Support'),
            content: const Text(
              'Help documentation and support options will be available here.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('About Product Management App'),
            content: const Text(
              'Version 1.0.0\n\n'
              'A comprehensive product management and label printing solution with bilingual support.\n\n'
              'Features:\n'
              '• Product inventory management\n'
              '• Barcode scanning\n'
              '• Label printing (Avery & custom formats)\n'
              '• Price tracking\n'
              '• Bilingual support (English/Persian)',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
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
      if (fullRepair || await _databaseService.isDatabaseReadOnly()) {
        if (kDebugMode) {
          print('Performing full database repair');
        }
        await _databaseService.recreateProductsTable();
      }

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
