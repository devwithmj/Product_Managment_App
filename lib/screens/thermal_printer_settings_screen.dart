import 'package:flutter/material.dart';
import '../services/thermal_print_service.dart';
import '../utils/constants.dart';

class ThermalPrinterSettingsScreen extends StatefulWidget {
  const ThermalPrinterSettingsScreen({super.key});

  @override
  _ThermalPrinterSettingsScreenState createState() =>
      _ThermalPrinterSettingsScreenState();
}

class _ThermalPrinterSettingsScreenState
    extends State<ThermalPrinterSettingsScreen> {
  ThermalConnectionType _connectionType = ThermalConnectionType.bluetooth;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  List<Map<String, String>> _availablePrinters = [];
  bool _isConnecting = false;
  bool _isTestPrinting = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPrinterStatus();
  }

  void _loadPrinterStatus() {
    setState(() {
      if (ThermalPrintService.isConnected) {
        final printer = ThermalPrintService.selectedPrinter;
        _statusMessage =
            'Connected to: ${ThermalPrintService.getPrinterDisplayName(printer)}';
      } else {
        _statusMessage = 'Not connected to any thermal printer';
      }
    });
  }

  Future<void> _scanForPrinters() async {
    setState(() {
      _statusMessage = 'Scanning for thermal printers...';
    });

    try {
      final printers = await ThermalPrintService.getAvailablePrinters(
        type: _connectionType,
      );

      setState(() {
        _availablePrinters = printers;
        if (printers.isEmpty) {
          _statusMessage = 'No printers found. Try manual connection.';
        } else {
          _statusMessage = 'Found ${printers.length} printer(s)';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error scanning: $e';
      });
    }
  }

  Future<void> _connectToPrinter(Map<String, String> printer) async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting to ${printer['name']}...';
    });

    try {
      final success = await ThermalPrintService.connectToPrinter(printer);

      setState(() {
        _isConnecting = false;
        if (success) {
          _statusMessage = 'Successfully connected to ${printer['name']}';
        } else {
          _statusMessage = 'Failed to connect to ${printer['name']}';
        }
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Connection error: $e';
      });
    }
  }

  Future<void> _connectManually() async {
    if (_addressController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter printer address';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting to ${_addressController.text}...';
    });

    try {
      final success = await ThermalPrintService.connectToManualAddress(
        address: _addressController.text,
        type: _connectionType,
        name:
            _nameController.text.isEmpty
                ? 'Manual Printer'
                : _nameController.text,
      );

      setState(() {
        _isConnecting = false;
        if (success) {
          _statusMessage =
              'Successfully connected to ${_addressController.text}';
        } else {
          _statusMessage = 'Failed to connect to ${_addressController.text}';
        }
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Connection error: $e';
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      await ThermalPrintService.disconnect();
      setState(() {
        _statusMessage = 'Disconnected from thermal printer';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error disconnecting: $e';
      });
    }
  }

  Future<void> _testPrint() async {
    setState(() {
      _isTestPrinting = true;
      _statusMessage = 'Sending test print...';
    });

    try {
      final success = await ThermalPrintService.testPrint();
      setState(() {
        _isTestPrinting = false;
        if (success) {
          _statusMessage = 'Test print successful!';
        } else {
          _statusMessage = 'Test print failed';
        }
      });
    } catch (e) {
      setState(() {
        _isTestPrinting = false;
        _statusMessage = 'Test print error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Printer Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          ThermalPrintService.isConnected
                              ? Icons.check_circle
                              : Icons.cancel,
                          color:
                              ThermalPrintService.isConnected
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_statusMessage)),
                      ],
                    ),
                    if (ThermalPrintService.isConnected) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon:
                                _isTestPrinting
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.print),
                            label: const Text('Test Print'),
                            onPressed: _isTestPrinting ? null : _testPrint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.bluetooth_disabled),
                            label: const Text('Disconnect'),
                            onPressed: _disconnect,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Connection Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<ThermalConnectionType>(
                            title: const Text('Bluetooth'),
                            value: ThermalConnectionType.bluetooth,
                            groupValue: _connectionType,
                            onChanged: (value) {
                              setState(() {
                                _connectionType = value!;
                                _addressController.clear();
                                _availablePrinters.clear();
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<ThermalConnectionType>(
                            title: const Text('Network'),
                            value: ThermalConnectionType.network,
                            groupValue: _connectionType,
                            onChanged: (value) {
                              setState(() {
                                _connectionType = value!;
                                _addressController.clear();
                                _availablePrinters.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Manual Connection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manual Connection',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Printer Name (Optional)',
                        hintText: 'TSP100III',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText:
                            _connectionType == ThermalConnectionType.bluetooth
                                ? 'Bluetooth MAC Address'
                                : 'IP Address',
                        hintText:
                            _connectionType == ThermalConnectionType.bluetooth
                                ? '00:11:22:33:44:55'
                                : '192.168.1.100',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon:
                            _isConnecting
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.link),
                        label: const Text('Connect'),
                        onPressed: _isConnecting ? null : _connectManually,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // TSP100III Setup Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TSP100III Setup Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• For Bluetooth: Make sure the printer is in pairing mode\n'
                      '• For Network: Connect printer to same WiFi network\n'
                      '• Use 7.9cm thermal label paper\n'
                      '• Ensure printer is powered on and ready',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Note: This app is optimized for Star TSP100III thermal printer with 7.9cm wide labels.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
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

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
