import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:product_app/screens/barcode_scanner_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class ProductEditScreen extends StatefulWidget {
  final Product? product;

  // If product is null, we're adding a new product
  // If product is provided, we're editing an existing product
  const ProductEditScreen({super.key, this.product});

  @override
  _ProductEditScreenState createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();

  late TextEditingController _barcodeController;
  late TextEditingController _priceController;
  late TextEditingController _nameEnController;
  late TextEditingController _nameFaController;
  late TextEditingController _brandEnController;
  late TextEditingController _brandFaController;

  late UnitType _selectedUnitType;
  late StoreLocation _storeLocation;
  late LabelOptions _labelOptions;

  bool _isLoading = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product data or empty
    final product = widget.product;

    _nameEnController = TextEditingController(text: product?.nameEn ?? '');
    _nameFaController = TextEditingController(text: product?.nameFa ?? '');
    _brandEnController = TextEditingController(text: product?.brandEn ?? '');
    _brandFaController = TextEditingController(text: product?.brandFa ?? '');
    _priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    _barcodeController = TextEditingController(text: product?.barcode ?? '');

    _selectedUnitType = product?.unitType ?? UnitType.gr;
    _storeLocation = product?.storeLocation ?? StoreLocation.both;
    _labelOptions = product?.labelOptions ?? LabelOptions();
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameEnController.dispose();
    _nameFaController.dispose();
    _brandEnController.dispose();
    _brandFaController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();

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
      final barcodeScanRes = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BarcodeScannerScreen()),
      );

      // If user canceled the scan, it returns -1
      if (barcodeScanRes != '-1') {
        setState(() {
          _barcodeController.text = barcodeScanRes;
        });

        // Check if product with this barcode already exists
        final existingProduct = await _databaseService.getProductByBarcode(
          barcodeScanRes,
        );

        if (existingProduct != null &&
            (widget.product == null ||
                existingProduct.id != widget.product!.id)) {
          // Show warning if product exists
          if (mounted) {
            _showBarcodeExistsDialog(existingProduct);
          }
        }
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Platform error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning barcode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _showBarcodeExistsDialog(Product existingProduct) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Duplicate Barcode'),
            content: Text(
              'This barcode is already assigned to product "${existingProduct.nameEn}".\n\n'
              'Using the same barcode for multiple products may cause confusion.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => loadProduct(existingProduct),
                child: const Text('Continue Anyway'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final double price = double.parse(_priceController.text);
        final Product? oldProduct = widget.product;

        // Creating a new product or updating existing one
        final Product product;

        if (oldProduct == null) {
          // Create new product
          product = Product(
            id: const Uuid().v4(), // Generate unique ID
            nameEn: _nameEnController.text.trim(),
            nameFa: _nameFaController.text.trim(),
            brandEn: _brandEnController.text.trim(),
            brandFa: _brandFaController.text.trim(),
            unitType: _selectedUnitType,
            price: price,
            priceUpdated:
                true, // Will be set to true automatically if price is different
            storeLocation: _storeLocation,
            barcode: _barcodeController.text.trim(),
            labelOptions: _labelOptions,
          );
        } else {
          // Update existing product
          product = oldProduct.copyWith(
            nameEn: _nameEnController.text.trim(),
            nameFa: _nameFaController.text.trim(),
            brandEn: _brandEnController.text.trim(),
            brandFa: _brandFaController.text.trim(),
            unitType: _selectedUnitType,
            price:
                price, // Will automatically set priceUpdated to true if price changed
            storeLocation: _storeLocation,
            priceUpdated: true,
            barcode: _barcodeController.text.trim(),
            labelOptions: _labelOptions,
          );
        }

        // Save the product with price logging
        await _databaseService.saveProduct(product, oldProduct: oldProduct);

        // Return to previous screen with success
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        // Handle errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving product: $e'),
              backgroundColor: Colors.red,
            ),
          );

          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null
              ? AppStrings.addProduct
              : AppStrings.editProduct,
        ),
        actions: [
          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProduct,
            tooltip: AppStrings.save,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Barcode field with scan button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: const InputDecoration(
                                labelText: 'Barcode',
                                border: OutlineInputBorder(),
                                hintText: 'Scan or enter barcode',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: _isScanning ? null : _scanBarcode,
                              icon:
                                  _isScanning
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.qr_code_scanner),
                              label: const Text('Scan'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // English Name
                      TextFormField(
                        controller: _nameEnController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.productName,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Persian Name
                      TextFormField(
                        controller: _nameFaController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.productNamePersian,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter Persian product name';
                          }
                          return null;
                        },
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 16),

                      // English Brand
                      TextFormField(
                        controller: _brandEnController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.brandName,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter brand name';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Persian Brand
                      TextFormField(
                        controller: _brandFaController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.brandNamePersian,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter Persian brand name';
                          }
                          return null;
                        },
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 16),

                      // Unit Type Dropdown
                      DropdownButtonFormField<UnitType>(
                        decoration: const InputDecoration(
                          labelText: AppStrings.unit,
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedUnitType,
                        items:
                            UnitType.values.map((unit) {
                              return DropdownMenuItem<UnitType>(
                                value: unit,
                                child: Text(Product.getUnitTypeString(unit)),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedUnitType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Price
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.price,
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter price';
                          }
                          try {
                            final price = double.parse(value);
                            if (price <= 0) {
                              return 'Price must be greater than zero';
                            }
                          } catch (e) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Store Location
                      DropdownButtonFormField<StoreLocation>(
                        decoration: const InputDecoration(
                          labelText: AppStrings.storeLocation,
                          border: OutlineInputBorder(),
                        ),
                        value: _storeLocation,
                        items: [
                          const DropdownMenuItem(
                            value: StoreLocation.downtown,
                            child: Text(AppStrings.downtown),
                          ),
                          const DropdownMenuItem(
                            value: StoreLocation.uptown,
                            child: Text(AppStrings.uptown),
                          ),
                          const DropdownMenuItem(
                            value: StoreLocation.both,
                            child: Text(AppStrings.both),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _storeLocation = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Label Options Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Label Options',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                title: const Text('Show Price'),
                                subtitle: const Text(
                                  'Display product price on label',
                                ),
                                value: _labelOptions.showPrice,
                                onChanged: (value) {
                                  setState(() {
                                    _labelOptions = _labelOptions.copyWith(
                                      showPrice: value,
                                    );
                                  });
                                },
                                dense: true,
                              ),
                              CheckboxListTile(
                                title: const Text('Show Size'),
                                subtitle: const Text(
                                  'Display product size on label',
                                ),
                                value: _labelOptions.showSize,
                                onChanged: (value) {
                                  setState(() {
                                    _labelOptions = _labelOptions.copyWith(
                                      showSize: value,
                                    );
                                  });
                                },
                                dense: true,
                              ),
                              CheckboxListTile(
                                title: const Text('Show Barcode'),
                                subtitle: const Text(
                                  'Display barcode on label as PLU',
                                ),
                                value: _labelOptions.showBarcode,
                                onChanged: (value) {
                                  setState(() {
                                    _labelOptions = _labelOptions.copyWith(
                                      showBarcode: value,
                                    );
                                  });
                                },
                                dense: true,
                              ),
                              CheckboxListTile(
                                title: const Text('Show English Name'),
                                subtitle: const Text(
                                  'Display English product name',
                                ),
                                value: _labelOptions.showEnglishName,
                                onChanged: (value) {
                                  setState(() {
                                    _labelOptions = _labelOptions.copyWith(
                                      showEnglishName: value,
                                    );
                                  });
                                },
                                dense: true,
                              ),
                              CheckboxListTile(
                                title: const Text('Show Persian Name'),
                                subtitle: const Text(
                                  'Display Persian product name',
                                ),
                                value: _labelOptions.showPersianName,
                                onChanged: (value) {
                                  setState(() {
                                    _labelOptions = _labelOptions.copyWith(
                                      showPersianName: value,
                                    );
                                  });
                                },
                                dense: true,
                              ),
                              CheckboxListTile(
                                title: const Text('Show Brand'),
                                subtitle: const Text(
                                  'Include brand name in labels',
                                ),
                                value: _labelOptions.showBrand,
                                onChanged: (value) {
                                  setState(() {
                                    _labelOptions = _labelOptions.copyWith(
                                      showBrand: value,
                                    );
                                  });
                                },
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            widget.product == null
                                ? 'Add Product'
                                : 'Update Product',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  void loadProduct(Product existingProduct) {
    // Close the current page
    Navigator.pop(context);
    // Navigate to the edit screen with the existing product
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductEditScreen(product: existingProduct),
      ),
    );
  }
}
