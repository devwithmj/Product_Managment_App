import 'package:flutter/foundation.dart';
import 'services/database_service.dart';
import 'models/product.dart';

Future<void> testDatabase() async {
  try {
    print('Testing database initialization...');
    final dbService = DatabaseService();

    print('Getting products...');
    final products = await dbService.getProducts();
    print('Found ${products.length} products');

    // Test creating a simple product
    print('Testing product creation...');
    final testProduct = Product(
      id: 'test-123',
      nameEn: 'Test Product',
      nameFa: 'محصول تست',
      brandEn: 'Test Brand',
      brandFa: 'برند تست',
      unitType: UnitType.gr,
      price: 9.99,
      barcode: '1234',
      labelOptions: const LabelOptions(),
    );

    print('Product created successfully');
    print('Database initialization appears to be working');
  } catch (e) {
    print('Database error: $e');
    if (kDebugMode) {
      print('Stack trace: ${StackTrace.current}');
    }
  }
}
