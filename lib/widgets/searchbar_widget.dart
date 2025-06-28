import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:product_app/screens/barcode_scanner_screen.dart';
import '../utils/constants.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onClear;
  final String hintText;
  final bool showFilter;
  final VoidCallback? onFilterTap;

  const SearchBarWidget({
    Key? key,
    required this.onSearch,
    required this.onClear,
    this.hintText = 'Search by name or barcode',
    this.showFilter = false,
    this.onFilterTap,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Check and request camera permission
  Future<bool> _requestCameraPermission() async {
    // Check camera permission
    var status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    // Request permission if not granted
    if (status.isDenied) {
      status = await Permission.camera.request();
      return status.isGranted;
    }

    // If permission is permanently denied, open app settings
    if (status.isPermanentlyDenied) {
      _showPermissionDialog();
      return false;
    }

    return false;
  }

  // Show dialog to explain permission need
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text(
              'This app needs camera access to scan barcodes. Please grant camera permission in app settings.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  // Scan barcode
  Future<void> _scanBarcode() async {
    // Don't allow multiple scan attempts simultaneously
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      // Request camera permission
      bool hasPermission = await _requestCameraPermission();

      if (!hasPermission) {
        setState(() {
          _isScanning = false;
        });
        return;
      }

      // Navigate to barcode scanner screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BarcodeScannerScreen()),
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _searchController.text = result;
        });

        // Trigger search with the scanned barcode
        widget.onSearch(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
    });
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            // Search text field
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                          : null,
                ),
                onChanged: widget.onSearch,
                textInputAction: TextInputAction.search,
                onSubmitted: widget.onSearch,
              ),
            ),

            // Barcode scan button
            IconButton(
              icon:
                  _isScanning
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                      : const Icon(Icons.qr_code_scanner),
              onPressed: _isScanning ? null : _scanBarcode,
              tooltip: 'Scan Barcode',
            ),

            // Optional filter button
            if (widget.showFilter)
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: widget.onFilterTap,
                tooltip: 'Filter Options',
              ),
          ],
        ),
      ),
    );
  }
}
