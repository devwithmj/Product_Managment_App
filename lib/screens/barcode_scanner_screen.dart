import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied) {
        if (mounted) {
          _showPermissionDialog();
        }
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'This app needs camera permission to scan barcodes. Please allow camera access in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, null);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final currentContext = context;
              Navigator.pop(currentContext);
              Future.microtask(() async {
                await openAppSettings();
                if (mounted) {
                  Navigator.pop(currentContext, null);
                }
              });
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture barcodes) {
    if (_isScanned) return; // Prevent multiple scans
    
    if (barcodes.barcodes.isNotEmpty) {
      final barcode = barcodes.barcodes.first;
      if (barcode.displayValue != null && barcode.displayValue!.isNotEmpty) {
        setState(() {
          _isScanned = true;
        });
        
        // Vibrate on successful scan (if available)
        // HapticFeedback.mediumImpact();
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned: ${barcode.displayValue}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
        
        // Store context before async operation
        final currentContext = context;
        
        // Return to previous screen with result
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(currentContext, barcode.displayValue);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_off),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scanner view
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          
          // Scan area overlay
          _buildScanOverlay(),
          
          // Bottom instruction bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: const Color.fromRGBO(0, 0, 0, 0.7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Point camera at barcode',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (_isScanned)
                    const Text(
                      'Barcode detected!',
                      style: TextStyle(color: Colors.green, fontSize: 14),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isScanned ? Colors.green : Colors.white,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Corner indicators
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: _isScanned ? Colors.green : Colors.white, width: 4),
                    left: BorderSide(color: _isScanned ? Colors.green : Colors.white, width: 4),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: _isScanned ? Colors.green : Colors.white, width: 4),
                    right: BorderSide(color: _isScanned ? Colors.green : Colors.white, width: 4),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: _isScanned ? Colors.green : Colors.white, width: 4),
                    left: BorderSide(color: _isScanned ? Colors.green : Colors.white, width: 4),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: _isScanned ? Colors.green : Colors.white, width: 4),
                    right: BorderSide(color: _isScanned ? Colors.green : Colors.white, width: 4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
