import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:product_app/widgets/searchbar_widget.dart';
import '../models/product.dart';
import '../models/label_template.dart';
import '../services/database_service.dart';
import '../services/print_service.dart';
import '../utils/constants.dart';
import '../widgets/product_item.dart';
import 'label_preview_screen.dart';

class PrintScreen extends StatefulWidget {
  const PrintScreen({Key? key}) : super(key: key);

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

  Future<void> _generatePreview() async {
    if (_selectedProducts.isEmpty) {
      _showErrorSnackBar('Please select at least one product');
      return;
    }

    setState(() {
      _isGeneratingPreview = true;
      _pdfData = null;
      _hasPrintError = false;
      _errorMessage = '';
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
        _errorMessage = 'Error generating preview: $e';
      });

      _showErrorSnackBar('Error generating preview: $e');
    }
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
                        LabelTemplates.allSizes.map((size) {
                          return DropdownMenuItem<LabelSize>(
                            value: size,
                            child: Text(size.name),
                          );
                        }).toList(),
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
                      }).toList(),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected: ${_selectedProducts.length} of ${_allProducts.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
          // Original Preview and Print buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.preview),
                  label: const Text(AppStrings.preview),
                  onPressed:
                      _selectedProducts.isEmpty || _isGeneratingPreview
                          ? null
                          : _generatePreview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset price flags for $updatedCount products'),
          backgroundColor: Colors.green,
        ),
      );

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
