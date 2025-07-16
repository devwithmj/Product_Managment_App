import 'package:flutter/material.dart';
import 'package:product_app/widgets/searchbar_widget.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/product_item.dart';
import 'product_edit_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  StoreLocation? _locationFilter;
  bool? _priceUpdatedFilter;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
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
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading products: $e');
      _showErrorSnackBar('Error loading products: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _addNewProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductEditScreen()),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  Future<void> _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductEditScreen(product: product),
      ),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  Future<void> _duplicateProduct(Product product) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.duplicateProduct(product.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.nameEn} has been duplicated'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadProducts();
    } catch (e) {
      _showErrorSnackBar('Error duplicating product: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text('Are you sure you want to delete ${product.nameEn}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteProduct(product.id);
        _loadProducts();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      } catch (e) {
        _showErrorSnackBar('Error deleting product: $e');
      }
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadProducts();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
    });
    _loadProducts();
  }

  void _toggleFilterPanel() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
    });
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
                false, // Don't need filter toggle - we keep filters visible
          ),

          // Filter options (keep original)
          _buildFilterOptions(),

          // Product list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _products.isEmpty
                    ? _buildEmptyState()
                    : _buildProductList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProduct,
        tooltip: AppStrings.addProduct,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
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
          if (_searchQuery.isEmpty)
            ElevatedButton(
              onPressed: _addNewProduct,
              child: const Text('Add your first product'),
            )
          else
            ElevatedButton(
              onPressed: _clearSearch,
              child: const Text('Clear search'),
            ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ProductItem(
          product: product,
          isSelected: false, // Selection is handled in the print screen
          onSelected: (_) {}, // No-op since selection is not used here
          onEdit: () => _editProduct(product),
          onDelete: () => _deleteProduct(product),
          onDuplicate: () => _duplicateProduct(product),
        );
      },
    );
  }
}
