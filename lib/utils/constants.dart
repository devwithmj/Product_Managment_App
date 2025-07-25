import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color accent = Color(0xFFFFA000);
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color priceUpdated = Color(0xFFF44336);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

class AppFonts {
  static const String englishFont = 'Roboto';
  static const String persianFont = 'Vazirmatn';
}

class AppStrings {
  static const String appTitle = 'Product Label Printing';
  static const String products = 'Products';
  static const String printLabels = 'Print Labels';
  static const String preview = 'Preview';
  static const String print = 'Print';
  static const String addProduct = 'Add Product';
  static const String editProduct = 'Edit Product';
  static const String deleteProduct = 'Delete Product';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String productName = 'Product Name';
  static const String productNamePersian = 'Product Name (Persian)';
  static const String brandName = 'Brand Name';
  static const String brandNamePersian = 'Brand Name (Persian)';
  static const String size = 'Size/Weight';
  static const String weightSize = 'Weight/Size Value';
  static const String unit = 'Unit';
  static const String price = 'Price';
  static const String storeLocation = 'Store Location';
  static const String priceUpdated = 'Price Updated';
  static const String downtown = 'Downtown';
  static const String uptown = 'Uptown';
  static const String both = 'Both Stores';
  static const String selectLabelSize = 'Select Label Size';
  static const String generatingPreview = 'Generating Preview...';
  static const String printing = 'Printing...';
  static const String selectProducts = 'Select Products';
  static const String noProductsSelected = 'No products selected';
  static const String labelPreview = 'Label Preview';
  static const String pagePreview = 'Page Preview';
  static const String priceHistory = 'Price History';
  static const String noHistoryAvailable = 'No price history available';
}

class AppConfig {
  // Database config
  static const String databaseName = 'label_printing.db';
  static const int databaseVersion =
      6; // Increased to handle barcode as PLU and label options
  static const String productsTable = 'products';
  static const String priceLogsTable = 'price_logs';

  // Printing config
  static const double printDPI = 96.0; // Default Flutter DPI
}
