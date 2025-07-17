import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:product_app/widgets/searchbar_widget.dart';
import '../models/product.dart';
import '../models/label_template.dart';
import '../services/database_service.dart';
import '../services/print_service.dart';
import '../services/thermal_print_service.dart';
import '../utils/constants.dart';
import '../widgets/product_item.dart';
import 'label_preview_screen.dart';
import 'thermal_printer_settings_screen.dart';

class PrintScreen extends StatefulWidget {
  const PrintScreen({super.key});

  @override
  _PrintScreenState createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _searchQuery = '';
  bool _isFilterExpanded = false;
  List<Product> _allProducts = [];
  List<Product> _selectedProducts = [];
  bool _isLoading = true;
  bool _isGeneratingPreview = false;
  bool _hasPrintError = false;
  String _errorMessage = '';

  // Filters
  StoreLocation? _locationFilter;
  bool? _priceUpdatedFilter;

  // Selected label template
  LabelSize _selectedLabelSize = LabelTemplates.standard;

  // Print method selection
  bool _useThermalPrinter = false;

  // Generated PDF data
  Uint8List? _pdfData;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _selectedProducts.clear(); // Clear selection when searching
      _pdfData = null; // Clear any generated PDF
    });
    _loadProducts();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _pdfData = null; // Clear any generated PDF
    });
    _loadProducts();
  }

  void _toggleFilterPanel() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _hasPrintError = false;
      _errorMessage = '';
    });

    try {
      List<Product> products;

      if (_searchQuery.isEmpty) {
        // No search query, use regular filters
        products = await _databaseService.getFilteredProducts(
          priceUpdated: _priceUpdatedFilter,
          storeLocation: _locationFilter,
        );
      } else {
        // Search with query and filters
        products = await _databaseService.searchProducts(
          query: _searchQuery,
          priceUpdated: _priceUpdatedFilter,
          storeLocation: _locationFilter,
        );
      }

      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasPrintError = true;
        _errorMessage = 'Error loading products: $e';
      });

      _showErrorSnackBar('Error loading products: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _toggleProductSelection(Product product, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedProducts.add(product);
      } else {
        _selectedProducts.removeWhere((p) => p.id == product.id);
      }

      // Clear any generated preview when selection changes
      _pdfData = null;
    });
  }

  void _selectAll() {
    setState(() {
      _selectedProducts = List.from(_allProducts);
      _pdfData = null;
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedProducts.clear();
      _pdfData = null;
    });
  }

  int _getUniqueProductCount() {
    if (_selectedProducts.isEmpty) return 0;

    // Count unique products by ID
    final uniqueIds = <String>{};
    for (final product in _selectedProducts) {
      uniqueIds.add(product.id);
    }
    return uniqueIds.length;
  }

  Future<void> _fillAverySheet(Product product) async {
    // Calculate how many labels fit on the selected template
    final int labelsPerPage =
        _selectedLabelSize.rowsPerPage * _selectedLabelSize.columnsPerPage;

    setState(() {
      // Fill the selection with the same product repeated for one full page
      _selectedProducts = List.generate(labelsPerPage, (index) => product);
      _pdfData = null; // Clear any generated preview
    });

    // Automatically print without notification
    await _printLabelsDirectly();
  }

  Future<void> _fillAverySheetWithSelectedProducts() async {
    if (_selectedProducts.isEmpty) {
      _showErrorSnackBar('Please select at least one product');
      return;
    }

    // Calculate how many labels fit on the selected template
    final int labelsPerPage =
        _selectedLabelSize.rowsPerPage * _selectedLabelSize.columnsPerPage;

    // Get unique products from selection
    final uniqueProducts = <Product>[];
    final seenIds = <String>{};

    for (final product in _selectedProducts) {
      if (!seenIds.contains(product.id)) {
        uniqueProducts.add(product);
        seenIds.add(product.id);
      }
    }

    setState(() {
      // Create separate pages for each unique product
      _selectedProducts.clear();

      for (final product in uniqueProducts) {
        // Add one full page of this product
        _selectedProducts.addAll(
          List.generate(labelsPerPage, (index) => product),
        );
      }

      _pdfData = null; // Clear any generated preview
    });

    // Automatically print without notification
    await _printLabelsDirectly();
  }

  Future<void> _printLabels() async {
    try {
      setState(() {
        _hasPrintError = false;
        _errorMessage = '';
      });

      if (_selectedProducts.isEmpty) {
        _showErrorSnackBar('Please select at least one product');
        return;
      }

      // Check if using thermal printer
      if (_useThermalPrinter) {
        await _printWithThermalPrinter();
        return;
      }

      // Continue with PDF printing for non-thermal
      if (_pdfData == null) {
        setState(() {
          _isGeneratingPreview = true;
        });

        try {
          final pdfBytes = await PrintService.generatePdf(
            products: _selectedProducts,
            labelSize: _selectedLabelSize,
          );

          setState(() {
            _pdfData = pdfBytes;
            _isGeneratingPreview = false;
          });
        } catch (e) {
          setState(() {
            _isGeneratingPreview = false;
            _hasPrintError = true;
            _errorMessage = 'Error generating PDF: $e';
          });

          _showErrorSnackBar('Error generating PDF: $e');
          return;
        }
      }

      if (_pdfData != null && _pdfData!.isNotEmpty && mounted) {
        try {
          await PrintService.printPdf(_pdfData!);
        } catch (e) {
          setState(() {
            _hasPrintError = true;
            _errorMessage = 'Error printing: $e';
          });

          _showErrorSnackBar('Error printing: $e');
        }
      } else {
        _showErrorSnackBar('No PDF data available for printing');
      }
    } catch (e) {
      setState(() {
        _hasPrintError = true;
        _errorMessage = 'Unexpected error during printing: $e';
      });

      _showErrorSnackBar('Unexpected error during printing: $e');
    }
  }

  Future<void> _printLabelsDirectly() async {
    try {
      if (_selectedProducts.isEmpty) {
        return;
      }

      // Check if using thermal printer
      if (_useThermalPrinter) {
        await _printWithThermalPrinter();
        return;
      }

      // Generate PDF directly without any UI feedback for non-thermal
      final pdfBytes = await PrintService.generatePdf(
        products: _selectedProducts,
        labelSize: _selectedLabelSize,
      );

      // Print directly without showing the print dialog preview
      await PrintService.printPdf(pdfBytes);
    } catch (e) {
      // Silent error handling - only show error if something critical happens
      if (mounted) {
        _showErrorSnackBar('Printing failed: $e');
      }
    }
  }

  // Thermal printer methods
  Future<void> _printWithThermalPrinter() async {
    if (!ThermalPrintService.isConnected) {
      _showErrorSnackBar(
        'Thermal printer not connected. Please check settings.',
      );
      return;
    }

    setState(() {
      _isGeneratingPreview = true;
    });

    try {
      final success = await ThermalPrintService.printMultipleLabels(
        _selectedProducts,
        _selectedLabelSize,
      );

      setState(() {
        _isGeneratingPreview = false;
      });

      if (success) {
        _showSuccessSnackBar(
          '${_selectedProducts.length} labels printed successfully!',
        );
      } else {
        _showErrorSnackBar(
          'Failed to print labels. Check thermal printer connection.',
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingPreview = false;
      });
      _showErrorSnackBar('Thermal printing error: $e');
    }
  }

  // Print single label with thermal printer
  Future<void> _printSingleThermalLabel(Product product) async {
    if (!ThermalPrintService.isConnected) {
      _showErrorSnackBar(
        'Thermal printer not connected. Please check settings.',
      );
      return;
    }

    try {
      final success = await ThermalPrintService.printSingleLabel(
        product,
        _selectedLabelSize,
      );

      if (success) {
        _showSuccessSnackBar('Label printed successfully!');
      } else {
        _showErrorSnackBar(
          'Failed to print label. Check thermal printer connection.',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Thermal printing error: $e');
    }
  }

  void _previewSingleLabel(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LabelPreviewScreen(
              product: product,
              labelSize: _selectedLabelSize,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar (new)
          SearchBarWidget(
            onSearch: _handleSearch,
            onClear: _clearSearch,
            hintText: 'Search by name, brand or barcode',
            showFilter:
                false, // Don't show filter toggle - we keep filters visible
          ),

          // Filters and settings (keep original)
          _buildPrintSettings(),

          // Error message if applicable
          if (_hasPrintError)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _hasPrintError = false;
                        _errorMessage = '';
                      });
                    },
                  ),
                ],
              ),
            ),

          // Product list for selection
          Expanded(
            flex: 3,
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildProductSelectionList(),
          ),

          // Preview and print actions
          _buildPreviewAndPrintActions(),

          // Loading indicator for preview generation
          if (_isGeneratingPreview)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppStrings.generatingPreview),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrintSettings() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Print Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // Print method selection
            Row(
              children: [
                const Text(
                  'Print Method:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('PDF Printer'),
                          value: false,
                          groupValue: _useThermalPrinter,
                          onChanged: (value) {
                            setState(() {
                              _useThermalPrinter = value!;
                              // Reset label size based on print method
                              if (!_useThermalPrinter &&
                                  LabelTemplates.isThermalSize(
                                    _selectedLabelSize,
                                  )) {
                                _selectedLabelSize = LabelTemplates.standard;
                              }
                              _pdfData = null;
                            });
                          },
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Thermal'),
                          value: true,
                          groupValue: _useThermalPrinter,
                          onChanged: (value) {
                            setState(() {
                              _useThermalPrinter = value!;
                              // Switch to thermal label size
                              if (_useThermalPrinter) {
                                _selectedLabelSize = LabelTemplates.thermal;
                              }
                              _pdfData = null;
                            });
                          },
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_useThermalPrinter)
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const ThermalPrinterSettingsScreen(),
                        ),
                      );
                    },
                    tooltip: 'Thermal Printer Settings',
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Label size selection
            Row(
              children: [
                const Text(
                  'Label Size:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<LabelSize>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: _selectedLabelSize,
                    items:
                        (_useThermalPrinter
                                ? LabelTemplates.thermalSizes
                                : LabelTemplates.allSizes
                                    .where(
                                      (size) =>
                                          !LabelTemplates.isThermalSize(size),
                                    )
                                    .toList())
                            .map((size) {
                              return DropdownMenuItem<LabelSize>(
                                value: size,
                                child: Text(size.name),
                              );
                            })
                            .toList(),
                    onChanged: (LabelSize? value) {
                      if (value != null) {
                        setState(() {
                          _selectedLabelSize = value;
                          _pdfData = null; // Reset preview when size changes
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            if (_useThermalPrinter) ...[
              const SizedBox(height: 12),
              // Thermal printer status
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      ThermalPrintService.isConnected
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  border: Border.all(
                    color:
                        ThermalPrintService.isConnected
                            ? Colors.green
                            : Colors.orange,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      ThermalPrintService.isConnected
                          ? Icons.check_circle
                          : Icons.warning,
                      color:
                          ThermalPrintService.isConnected
                              ? Colors.green
                              : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ThermalPrintService.isConnected
                            ? 'Thermal printer connected'
                            : 'Thermal printer not connected - Go to settings',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Filters
            Row(
              children: [
                // Store Location Filter
                Expanded(
                  child: DropdownButtonFormField<StoreLocation?>(
                    decoration: const InputDecoration(
                      labelText: 'Store Location',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: _locationFilter,
                    items: [
                      const DropdownMenuItem<StoreLocation?>(
                        value: null,
                        child: Text('All Locations'),
                      ),
                      ...StoreLocation.values.map((location) {
                        String locationName;
                        switch (location) {
                          case StoreLocation.downtown:
                            locationName = AppStrings.downtown;
                            break;
                          case StoreLocation.uptown:
                            locationName = AppStrings.uptown;
                            break;
                          case StoreLocation.both:
                            locationName = AppStrings.both;
                            break;
                        }

                        return DropdownMenuItem<StoreLocation?>(
                          value: location,
                          child: Text(locationName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _locationFilter = value;
                        _selectedProducts.clear();
                        _pdfData = null;
                      });
                      _loadProducts();
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Price Updated Filter
                Expanded(
                  child: DropdownButtonFormField<bool?>(
                    decoration: const InputDecoration(
                      labelText: 'Price Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: _priceUpdatedFilter,
                    items: const [
                      DropdownMenuItem<bool?>(
                        value: null,
                        child: Text('All Prices'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: true,
                        child: Text('Updated Prices'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: false,
                        child: Text('Regular Prices'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _priceUpdatedFilter = value;
                        _selectedProducts.clear();
                        _pdfData = null;
                      });
                      _loadProducts();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelectionList() {
    if (_allProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No products found matching "$_searchQuery"'
                  : 'No products found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isNotEmpty)
              ElevatedButton(
                onPressed: _clearSearch,
                child: const Text('Clear search'),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Selection actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected: ${_selectedProducts.length} labels',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_selectedProducts.isNotEmpty)
                        Text(
                          '${_getUniqueProductCount()} unique products',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.select_all),
                        label: const Text('Select All'),
                        onPressed: _selectAll,
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.deselect),
                        label: const Text('Clear'),
                        onPressed: _deselectAll,
                      ),
                    ],
                  ),
                ],
              ),
              // Fill Sheet button row
              if (_selectedLabelSize.name.contains("Avery"))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.content_copy),
                              label: Text(
                                _selectedProducts.length == 1
                                    ? 'Fill ${_selectedLabelSize.name} Sheet'
                                    : 'Fill ${_selectedLabelSize.name} Pages (${_getUniqueProductCount()} pages)',
                              ),
                              onPressed:
                                  _selectedProducts.isEmpty
                                      ? null
                                      : _selectedProducts.length == 1
                                      ? () async => await _fillAverySheet(
                                        _selectedProducts.first,
                                      )
                                      : () async =>
                                          await _fillAverySheetWithSelectedProducts(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            if (_selectedProducts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  top: 4.0,
                                ),
                                child: Text(
                                  'Select products to fill pages',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              )
                            else if (_selectedProducts.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  top: 4.0,
                                ),
                                child: Text(
                                  'Creates one full page per unique product',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Product list
        Expanded(
          child: ListView.builder(
            itemCount: _allProducts.length,
            itemBuilder: (context, index) {
              final product = _allProducts[index];
              final isSelected = _selectedProducts.any(
                (p) => p.id == product.id,
              );

              return ProductItem(
                product: product,
                isSelected: isSelected,
                onSelected:
                    (selected) => _toggleProductSelection(product, selected),
                onEdit: () => _previewSingleLabel(product),
                onDelete: () {}, // No delete functionality on this screen
                onDuplicate:
                    _selectedLabelSize.name.contains("Avery")
                        ? () async => await _fillAverySheet(product)
                        : null, // Show fill sheet button only for Avery templates
                onPrint:
                    _useThermalPrinter && ThermalPrintService.isConnected
                        ? () async => await _printSingleThermalLabel(product)
                        : null, // Show print button only for thermal printing
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewAndPrintActions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Row with action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Price Flags'),
                  onPressed:
                      _selectedProducts.isEmpty || _isGeneratingPreview
                          ? null
                          : _resetPriceUpdatedFlags,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12), // Add spacing
          // Fill Pages and Print buttons (removed Preview)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.content_copy),
                  label: Text(
                    _selectedLabelSize.name.contains("Avery")
                        ? 'Fill ${_selectedLabelSize.name} Pages'
                        : 'Fill Label Pages',
                  ),
                  onPressed:
                      _selectedProducts.isEmpty || _isGeneratingPreview
                          ? null
                          : () async =>
                              await _fillAverySheetWithSelectedProducts(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text(AppStrings.print),
                  onPressed:
                      _selectedProducts.isEmpty || _isGeneratingPreview
                          ? null
                          : _printLabels,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resetPriceUpdatedFlags() async {
    if (_selectedProducts.isEmpty) {
      _showErrorSnackBar('Please select at least one product');
      return;
    }

    // First check if any products actually have the flag set
    final hasUpdatedProducts = _selectedProducts.any(
      (p) => p.priceUpdated || !p.priceUpdated,
    );

    if (!hasUpdatedProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No selected products have price update flags to reset',
          ),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Price Updated Flags'),
            content: Text(
              'This will reset the price update status for ${_selectedProducts.length} selected products. '
              'Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reset Flags'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Extract IDs of products with the flag set
      final Map<String, bool> productIdAndFlagMap = {
        for (var p in _selectedProducts) p.id: p.priceUpdated,
      };

      // Use the optimized database method to reset flags
      final updatedCount = await _databaseService.resetPriceUpdatedFlags(
        productIdAndFlagMap,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset price flags for $updatedCount products'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload the products list
      await _loadProducts();
    } catch (e) {
      _showErrorSnackBar('Error resetting price flags: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
