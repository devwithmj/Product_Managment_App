import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../models/price_log.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  // In-memory cache of products and price logs as a fallback for iOS
  List<Product> _productsCache = [];
  List<PriceLog> _priceLogsCache = [];
  bool _cacheLoaded = false;

  // File-based backup paths
  late String _productBackupFilePath;
  late String _priceLogBackupFilePath;
  bool _isInitialized = false;

  // Initialize the service
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      // Set up backup file paths
      final documentsDirectory = await getApplicationDocumentsDirectory();
      _productBackupFilePath = join(
        documentsDirectory.path,
        'products_backup.json',
      );
      _priceLogBackupFilePath = join(
        documentsDirectory.path,
        'price_logs_backup.json',
      );

      // Try to load from backup files
      await _loadFromBackup();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing database service: $e');
    }
  }

  // Get database instance, or null if it cannot be opened
  Future<Database?> _getDatabaseIfPossible() async {
    if (_database != null && _database!.isOpen) {
      return _database;
    }

    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, AppConfig.databaseName);

      // Try to open database
      final db = await openDatabase(
        dbPath,
        version: AppConfig.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        readOnly: false,
      );

      // Test if it's writable using a better approach:
      // Try a simple insert/delete operation on a temporary table
      try {
        // Create a test table (if it doesn't exist)
        await db.execute(
          'CREATE TABLE IF NOT EXISTS _write_test_table (id INTEGER PRIMARY KEY)',
        );

        // Insert a test row
        int testId = await db.insert('_write_test_table', {
          'id': DateTime.now().millisecondsSinceEpoch,
        });

        // Delete the test row immediately
        await db.delete(
          '_write_test_table',
          where: 'id = ?',
          whereArgs: [testId],
        );

        // If we got here, the database is writable
        _database = db;
        return db;
      } catch (e) {
        print('Database is read-only (write test failed): $e');
        await db.close();
        return null;
      }
    } catch (e) {
      print('Could not open database, falling back to file storage: $e');
      return null;
    }
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConfig.productsTable} (
        id TEXT PRIMARY KEY,
        nameEn TEXT NOT NULL,
        nameFa TEXT NOT NULL,
        brandEn TEXT NOT NULL,
        brandFa TEXT NOT NULL,
        sizeValue TEXT NOT NULL,
        unitType INTEGER NOT NULL,
        price REAL NOT NULL,
        priceUpdated INTEGER NOT NULL,
        storeLocation INTEGER NOT NULL,
        barcode TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConfig.priceLogsTable} (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        oldPrice REAL NOT NULL,
        newPrice REAL NOT NULL,
        changeDate INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (productId) REFERENCES ${AppConfig.productsTable} (id) ON DELETE CASCADE
      )
    ''');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from $oldVersion to $newVersion');

    if (oldVersion < 2) {
      try {
        final tableInfo = await db.rawQuery(
          "PRAGMA table_info(${AppConfig.productsTable})",
        );
        if (!tableInfo.any((column) => column['name'] == 'barcode')) {
          await db.execute(
            'ALTER TABLE ${AppConfig.productsTable} ADD COLUMN barcode TEXT',
          );
        }
      } catch (e) {
        print('Error upgrading database: $e');
      }
    }

    if (oldVersion < 3) {
      try {
        final tableInfo = await db.rawQuery(
          "PRAGMA table_info(${AppConfig.productsTable})",
        );

        if (!tableInfo.any((column) => column['name'] == 'createdAt')) {
          await db.execute(
            'ALTER TABLE ${AppConfig.productsTable} ADD COLUMN createdAt INTEGER DEFAULT ${DateTime.now().millisecondsSinceEpoch}',
          );
        }

        if (!tableInfo.any((column) => column['name'] == 'updatedAt')) {
          await db.execute(
            'ALTER TABLE ${AppConfig.productsTable} ADD COLUMN updatedAt INTEGER DEFAULT ${DateTime.now().millisecondsSinceEpoch}',
          );
        }

        if (!tableInfo.any((column) => column['name'] == 'unitType')) {
          await db.execute(
            'ALTER TABLE ${AppConfig.productsTable} ADD COLUMN unitType INTEGER DEFAULT 0',
          );
        }

        if (!tableInfo.any((column) => column['name'] == 'sizeValue')) {
          await db.execute(
            'ALTER TABLE ${AppConfig.productsTable} ADD COLUMN sizeValue TEXT DEFAULT ""',
          );
        }
      } catch (e) {
        print('Error during upgrade: $e');
      }
    }

    if (oldVersion < 4) {
      try {
        final tableExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='${AppConfig.priceLogsTable}'",
        );

        if (tableExists.isEmpty) {
          await db.execute('''
            CREATE TABLE ${AppConfig.priceLogsTable} (
              id TEXT PRIMARY KEY,
              productId TEXT NOT NULL,
              oldPrice REAL NOT NULL,
              newPrice REAL NOT NULL,
              changeDate INTEGER NOT NULL,
              notes TEXT,
              FOREIGN KEY (productId) REFERENCES ${AppConfig.productsTable} (id) ON DELETE CASCADE
            )
          ''');
        }
      } catch (e) {
        print('Error creating price logs table: $e');
      }
    }
  }

  // Load products and price logs from backup files
  Future<void> _loadFromBackup() async {
    try {
      // Load products
      final productFile = File(_productBackupFilePath);
      if (await productFile.exists()) {
        final content = await productFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);

        _productsCache = jsonList.map((json) => Product.fromMap(json)).toList();
        print('Loaded ${_productsCache.length} products from backup file');
      }

      // Load price logs
      final logFile = File(_priceLogBackupFilePath);
      if (await logFile.exists()) {
        final content = await logFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);

        _priceLogsCache =
            jsonList.map((json) => PriceLog.fromMap(json)).toList();
        print('Loaded ${_priceLogsCache.length} price logs from backup file');
      }

      _cacheLoaded = true;
    } catch (e) {
      print('Error loading from backup: $e');
      _productsCache = [];
      _priceLogsCache = [];
      _cacheLoaded = true;
    }
  }

  // Save products to backup file
  Future<void> _saveProductsToBackup() async {
    try {
      final file = File(_productBackupFilePath);
      final jsonList =
          _productsCache.map((product) => product.toMap()).toList();
      await file.writeAsString(jsonEncode(jsonList));
      print('Saved ${_productsCache.length} products to backup file');
    } catch (e) {
      print('Error saving products to backup: $e');
    }
  }

  // Save price logs to backup file
  Future<void> _savePriceLogsToBackup() async {
    try {
      final file = File(_priceLogBackupFilePath);
      final jsonList = _priceLogsCache.map((log) => log.toMap()).toList();
      await file.writeAsString(jsonEncode(jsonList));
      print('Saved ${_priceLogsCache.length} price logs to backup file');
    } catch (e) {
      print('Error saving price logs to backup: $e');
    }
  }

  // Reset connection (for external use)
  Future<void> resetDatabaseConnection() async {
    if (_database != null) {
      try {
        if (_database!.isOpen) {
          await _database!.close();
        }
      } catch (e) {
        print('Error closing database: $e');
      }
      _database = null;
    }

    // Force reload from backup
    _cacheLoaded = false;
    await _initialize();
  }

  // Check if database is read-only
  Future<bool> isDatabaseReadOnly() async {
    try {
      final db = await _getDatabaseIfPossible();
      return db ==
          null; // If we couldn't get a database, it's effectively read-only
    } catch (e) {
      print('Database is read-only: $e');
      return true;
    }
  }

  // Ensure the cache is loaded
  Future<void> _ensureCacheLoaded() async {
    await _initialize();
    if (!_cacheLoaded) {
      await _loadFromBackup();
    }
  }

  // Create/Update product with price logging
  Future<void> saveProduct(Product product, {Product? oldProduct}) async {
    try {
      await _ensureCacheLoaded();

      // Try to use database if available
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        // Begin transaction for atomicity
        await db.transaction((txn) async {
          // If this is an update and price has changed, log the price change
          if (oldProduct != null && oldProduct.price != product.price) {
            final priceLog = PriceLog(
              id: const Uuid().v4(),
              productId: product.id,
              oldPrice: oldProduct.price,
              newPrice: product.price,
              changeDate: DateTime.now(),
            );

            await txn.insert(
              AppConfig.priceLogsTable,
              priceLog.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            // Also update cache
            _priceLogsCache.add(priceLog);
            await _savePriceLogsToBackup();

            print(
              'Logged price change for ${product.nameEn}: ${oldProduct.price} -> ${product.price}',
            );
          }

          // Insert or update the product
          await txn.insert(
            AppConfig.productsTable,
            product.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Also update cache
          _productsCache.removeWhere((p) => p.id == product.id);
          _productsCache.add(product);
          await _saveProductsToBackup();
        });
      } else {
        // Use in-memory cache only

        // If this is an update and price has changed, log the price change
        if (oldProduct != null && oldProduct.price != product.price) {
          final priceLog = PriceLog(
            id: const Uuid().v4(),
            productId: product.id,
            oldPrice: oldProduct.price,
            newPrice: product.price,
            changeDate: DateTime.now(),
          );

          _priceLogsCache.add(priceLog);
          await _savePriceLogsToBackup();

          print(
            'Logged price change for ${product.nameEn}: ${oldProduct.price} -> ${product.price}',
          );
        }

        // Update product in cache
        _productsCache.removeWhere((p) => p.id == product.id);
        _productsCache.add(product);
        await _saveProductsToBackup();
      }

      print('Product saved: ${product.nameEn}');
    } catch (e) {
      print('Error saving product: $e');

      // Fallback to cache-only approach
      try {
        await _ensureCacheLoaded();

        // If this is an update and price has changed, log the price change
        if (oldProduct != null && oldProduct.price != product.price) {
          final priceLog = PriceLog(
            id: const Uuid().v4(),
            productId: product.id,
            oldPrice: oldProduct.price,
            newPrice: product.price,
            changeDate: DateTime.now(),
          );

          _priceLogsCache.add(priceLog);
          await _savePriceLogsToBackup();
        }

        _productsCache.removeWhere((p) => p.id == product.id);
        _productsCache.add(product);
        await _saveProductsToBackup();

        print('Product saved to cache: ${product.nameEn}');
      } catch (cacheError) {
        print('Fatal error saving product: $cacheError');
        rethrow;
      }
    }
  }

  // Read all products
  Future<List<Product>> getProducts() async {
    try {
      await _ensureCacheLoaded();

      // Try database first
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        final List<Map<String, dynamic>> maps = await db.query(
          AppConfig.productsTable,
        );
        final products = List.generate(
          maps.length,
          (i) => Product.fromMap(maps[i]),
        );

        // Update cache
        _productsCache = products;
        await _saveProductsToBackup();

        return products;
      } else {
        // Use cache
        return List.from(_productsCache);
      }
    } catch (e) {
      print('Error getting products: $e');

      // Fall back to cache
      await _ensureCacheLoaded();
      return List.from(_productsCache);
    }
  }

  // Read filtered products
  Future<List<Product>> getFilteredProducts({
    bool? priceUpdated,
    StoreLocation? storeLocation,
    String? barcodeQuery,
    String? nameQuery,
  }) async {
    try {
      await _ensureCacheLoaded();

      // Try database first
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        String whereClause = '';
        List<dynamic> whereArgs = [];

        if (priceUpdated != null) {
          whereClause += 'priceUpdated = ?';
          whereArgs.add(priceUpdated ? 1 : 0);
        }

        if (storeLocation != null) {
          if (whereClause.isNotEmpty) whereClause += ' AND ';

          if (storeLocation == StoreLocation.both) {
            whereClause += '(storeLocation = ? OR storeLocation = ?)';
            whereArgs.add(StoreLocation.both.index);
            whereArgs.add(StoreLocation.downtown.index);
            whereClause += ' OR storeLocation = ?';
            whereArgs.add(StoreLocation.uptown.index);
          } else {
            whereClause += '(storeLocation = ? OR storeLocation = ?)';
            whereArgs.add(storeLocation.index);
            whereArgs.add(StoreLocation.both.index);
          }
        }

        // Add barcode query if provided
        if (barcodeQuery != null && barcodeQuery.isNotEmpty) {
          if (whereClause.isNotEmpty) whereClause += ' AND ';
          whereClause += 'barcode LIKE ?';
          whereArgs.add('%$barcodeQuery%');
        }

        // Add name query if provided
        if (nameQuery != null && nameQuery.isNotEmpty) {
          if (whereClause.isNotEmpty) whereClause += ' AND ';
          whereClause +=
              '(nameEn LIKE ? OR nameFa LIKE ? OR brandEn LIKE ? OR brandFa LIKE ?)';
          whereArgs.add('%$nameQuery%');
          whereArgs.add('%$nameQuery%');
          whereArgs.add('%$nameQuery%');
          whereArgs.add('%$nameQuery%');
        }

        final List<Map<String, dynamic>> maps = await db.query(
          AppConfig.productsTable,
          where: whereClause.isNotEmpty ? whereClause : null,
          whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
          orderBy: 'createdAt DESC', // Most recent first
        );

        return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
      } else {
        // Filter in memory
        return _productsCache.where((product) {
          bool match = true;

          if (priceUpdated != null) {
            match = match && (product.priceUpdated == priceUpdated);
          }

          if (storeLocation != null) {
            if (storeLocation == StoreLocation.both) {
              match =
                  match &&
                  (product.storeLocation == StoreLocation.both ||
                      product.storeLocation == StoreLocation.downtown ||
                      product.storeLocation == StoreLocation.uptown);
            } else {
              match =
                  match &&
                  (product.storeLocation == storeLocation ||
                      product.storeLocation == StoreLocation.both);
            }
          }

          if (barcodeQuery != null && barcodeQuery.isNotEmpty) {
            match = match && product.barcode.contains(barcodeQuery);
          }

          if (nameQuery != null && nameQuery.isNotEmpty) {
            match =
                match &&
                (product.nameEn.toLowerCase().contains(
                      nameQuery.toLowerCase(),
                    ) ||
                    product.nameFa.contains(nameQuery) ||
                    product.brandEn.toLowerCase().contains(
                      nameQuery.toLowerCase(),
                    ) ||
                    product.brandFa.contains(nameQuery));
          }

          return match;
        }).toList();
      }
    } catch (e) {
      print('Error getting filtered products: $e');

      // Fall back to filtering in memory
      await _ensureCacheLoaded();
      return _productsCache.where((product) {
        bool match = true;

        if (priceUpdated != null) {
          match = match && (product.priceUpdated == priceUpdated);
        }

        if (storeLocation != null) {
          if (storeLocation == StoreLocation.both) {
            match =
                match &&
                (product.storeLocation == StoreLocation.both ||
                    product.storeLocation == StoreLocation.downtown ||
                    product.storeLocation == StoreLocation.uptown);
          } else {
            match =
                match &&
                (product.storeLocation == storeLocation ||
                    product.storeLocation == StoreLocation.both);
          }
        }

        if (barcodeQuery != null && barcodeQuery.isNotEmpty) {
          match = match && product.barcode.contains(barcodeQuery);
        }

        if (nameQuery != null && nameQuery.isNotEmpty) {
          match =
              match &&
              (product.nameEn.toLowerCase().contains(nameQuery.toLowerCase()) ||
                  product.nameFa.contains(nameQuery) ||
                  product.brandEn.toLowerCase().contains(
                    nameQuery.toLowerCase(),
                  ) ||
                  product.brandFa.contains(nameQuery));
        }

        return match;
      }).toList();
    }
  }

  // Get by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    if (barcode.isEmpty) return null;

    try {
      await _ensureCacheLoaded();

      // Try database first
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        final List<Map<String, dynamic>> maps = await db.query(
          AppConfig.productsTable,
          where: 'barcode = ?',
          whereArgs: [barcode],
          limit: 1,
        );

        if (maps.isEmpty) return null;
        return Product.fromMap(maps.first);
      } else {
        // Use cache
        return _productsCache.firstWhere(
          (p) => p.barcode == barcode,
          orElse: () => throw StateError('Not found'),
        );
      }
    } catch (e) {
      print('Error getting product by barcode: $e');

      // Fall back to cache
      try {
        await _ensureCacheLoaded();
        return _productsCache.firstWhere(
          (p) => p.barcode == barcode,
          orElse: () => throw StateError('Not found'),
        );
      } catch (e) {
        return null;
      }
    }
  }

  // Get by ID
  Future<Product?> getProduct(String id) async {
    try {
      await _ensureCacheLoaded();

      // Try database first
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        final List<Map<String, dynamic>> maps = await db.query(
          AppConfig.productsTable,
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (maps.isEmpty) return null;
        return Product.fromMap(maps.first);
      } else {
        // Use cache
        return _productsCache.firstWhere(
          (p) => p.id == id,
          orElse: () => throw StateError('Not found'),
        );
      }
    } catch (e) {
      print('Error getting product by ID: $e');

      // Fall back to cache
      try {
        await _ensureCacheLoaded();
        return _productsCache.firstWhere(
          (p) => p.id == id,
          orElse: () => throw StateError('Not found'),
        );
      } catch (e) {
        return null;
      }
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    try {
      await _ensureCacheLoaded();

      // Try database first
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        // Begin transaction
        await db.transaction((txn) async {
          // Delete related price logs first
          await txn.delete(
            AppConfig.priceLogsTable,
            where: 'productId = ?',
            whereArgs: [id],
          );

          // Delete the product
          await txn.delete(
            AppConfig.productsTable,
            where: 'id = ?',
            whereArgs: [id],
          );
        });
      }

      // Always update cache
      _productsCache.removeWhere((p) => p.id == id);
      _priceLogsCache.removeWhere((log) => log.productId == id);
      await _saveProductsToBackup();
      await _savePriceLogsToBackup();

      print('Product deleted: $id');
    } catch (e) {
      print('Error deleting product: $e');

      // Fallback to cache
      try {
        _productsCache.removeWhere((p) => p.id == id);
        _priceLogsCache.removeWhere((log) => log.productId == id);
        await _saveProductsToBackup();
        await _savePriceLogsToBackup();
      } catch (cacheError) {
        print('Fatal error deleting product: $cacheError');
        rethrow;
      }
    }
  }

  // Delete all products
  Future<void> deleteAllProducts() async {
    try {
      await _ensureCacheLoaded();

      // Try database first
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        // Begin transaction
        await db.transaction((txn) async {
          // Delete all price logs first
          await txn.delete(AppConfig.priceLogsTable);

          // Delete all products
          await txn.delete(AppConfig.productsTable);
        });
      }

      // Always clear cache
      _productsCache.clear();
      _priceLogsCache.clear();
      await _saveProductsToBackup();
      await _savePriceLogsToBackup();

      print('All products deleted');
    } catch (e) {
      print('Error deleting all products: $e');

      // Fallback to cache
      try {
        _productsCache.clear();
        _priceLogsCache.clear();
        await _saveProductsToBackup();
        await _savePriceLogsToBackup();
      } catch (cacheError) {
        print('Fatal error deleting all products: $cacheError');
        rethrow;
      }
    }
  }

  // Get price logs for a product
  Future<List<PriceLog>> getPriceLogs(String productId) async {
    try {
      await _ensureCacheLoaded();

      // Try database first
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        final maps = await db.query(
          AppConfig.priceLogsTable,
          where: 'productId = ?',
          whereArgs: [productId],
          orderBy: 'changeDate DESC', // Most recent first
        );

        return maps.map((map) => PriceLog.fromMap(map)).toList();
      } else {
        // Use cache
        return _priceLogsCache
            .where((log) => log.productId == productId)
            .toList()
          ..sort((a, b) => b.changeDate.compareTo(a.changeDate));
      }
    } catch (e) {
      print('Error getting price logs: $e');

      // Fall back to cache
      await _ensureCacheLoaded();
      return _priceLogsCache.where((log) => log.productId == productId).toList()
        ..sort((a, b) => b.changeDate.compareTo(a.changeDate));
    }
  }

  // Add a price log entry
  Future<void> addPriceLog(PriceLog log) async {
    try {
      await _ensureCacheLoaded();

      // Try database first
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        await db.insert(
          AppConfig.priceLogsTable,
          log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Always update cache
      _priceLogsCache.add(log);
      await _savePriceLogsToBackup();

      print(
        'Added price log: ${log.productId} (${log.oldPrice} -> ${log.newPrice})',
      );
    } catch (e) {
      print('Error adding price log: $e');

      // Fallback to cache
      try {
        _priceLogsCache.add(log);
        await _savePriceLogsToBackup();
      } catch (cacheError) {
        print('Fatal error adding price log: $cacheError');
        rethrow;
      }
    }
  }

  // Get recent price logs
  Future<List<PriceLog>> getRecentPriceLogs({int days = 30}) async {
    try {
      await _ensureCacheLoaded();

      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      // Try database first
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        final maps = await db.query(
          AppConfig.priceLogsTable,
          where: 'changeDate >= ?',
          whereArgs: [cutoffDate.millisecondsSinceEpoch],
          orderBy: 'changeDate DESC',
        );

        return maps.map((map) => PriceLog.fromMap(map)).toList();
      } else {
        // Use cache
        return _priceLogsCache
            .where((log) => log.changeDate.isAfter(cutoffDate))
            .toList()
          ..sort((a, b) => b.changeDate.compareTo(a.changeDate));
      }
    } catch (e) {
      print('Error getting recent price logs: $e');

      // Fall back to cache
      await _ensureCacheLoaded();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      return _priceLogsCache
          .where((log) => log.changeDate.isAfter(cutoffDate))
          .toList()
        ..sort((a, b) => b.changeDate.compareTo(a.changeDate));
    }
  }

  Future<int> resetPriceUpdatedFlags(List<String> productIds) async {
    try {
      await _ensureCacheLoaded();
      int updatedCount = 0;

      // Try database first
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        // Use transaction for efficiency with multiple updates
        await db.transaction((txn) async {
          for (String id in productIds) {
            int count = await txn.update(
              AppConfig.productsTable,
              {'priceUpdated': 0},
              where: 'id = ? AND priceUpdated = 1',
              whereArgs: [id],
            );
            updatedCount += count;
          }
        });
      }

      // Always update cache too
      for (int i = 0; i < _productsCache.length; i++) {
        final product = _productsCache[i];
        if (productIds.contains(product.id) && product.priceUpdated) {
          _productsCache[i] = product.copyWith(priceUpdated: false);
          updatedCount++;
        }
      }
      await _saveProductsToBackup();

      print('Reset price flags for $updatedCount products');
      return updatedCount;
    } catch (e) {
      print('Error resetting price flags: $e');

      // Fallback to cache
      try {
        int updatedCount = 0;
        for (int i = 0; i < _productsCache.length; i++) {
          final product = _productsCache[i];
          if (productIds.contains(product.id) && product.priceUpdated) {
            _productsCache[i] = product.copyWith(priceUpdated: false);
            updatedCount++;
          }
        }
        await _saveProductsToBackup();
        return updatedCount;
      } catch (cacheError) {
        print('Fatal error resetting price flags: $cacheError');
        rethrow;
      }
    }
  }

  // Nuclear option - recreate tables
  Future<void> recreateProductsTable() async {
    try {
      final db = await _database;

      // Backup data if possible
      List<Map<String, dynamic>> existingProducts = [];
      List<Map<String, dynamic>> existingLogs = [];
      try {
        existingProducts = await db!.query(AppConfig.productsTable);
        existingLogs = await db!.query(AppConfig.priceLogsTable);
        print(
          'Backed up ${existingProducts.length} products and ${existingLogs.length} logs',
        );
      } catch (e) {
        print('Error backing up data: $e');
      }

      // Drop and recreate tables
      await db!.transaction((txn) async {
        await txn.execute('DROP TABLE IF EXISTS ${AppConfig.priceLogsTable}');
        await txn.execute('DROP TABLE IF EXISTS ${AppConfig.productsTable}');

        // Recreate tables
        await _onCreate(txn.database, AppConfig.databaseVersion);

        // Restore data
        for (final product in existingProducts) {
          await txn.insert(
            AppConfig.productsTable,
            product,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final log in existingLogs) {
          await txn.insert(
            AppConfig.priceLogsTable,
            log,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      print('Successfully recreated database tables');
    } catch (e) {
      print('Error recreating database tables: $e');
      rethrow;
    }
  }
  // Add this method to your DatabaseService class

  // Duplicate a product
  Future<Product> duplicateProduct(String productId) async {
    try {
      await _ensureCacheLoaded();

      // Get the original product
      Product? originalProduct;

      // Try database first
      final db = await _getDatabaseIfPossible();
      if (db != null) {
        final List<Map<String, dynamic>> maps = await db.query(
          AppConfig.productsTable,
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );

        if (maps.isNotEmpty) {
          originalProduct = Product.fromMap(maps.first);
        }
      }

      // If not found in database, try cache
      if (originalProduct == null) {
        originalProduct = _productsCache.firstWhere(
          (p) => p.id == productId,
          orElse: () => throw Exception('Product not found'),
        );
      }

      // Create a duplicate with a new ID and "Copy" in the name
      final duplicatedProduct = Product(
        id: const Uuid().v4(), // Generate a new ID
        nameEn: '${originalProduct.nameEn} (Copy)',
        nameFa: '${originalProduct.nameFa} (کپی)',
        brandEn: originalProduct.brandEn,
        brandFa: originalProduct.brandFa,
        sizeValue: originalProduct.sizeValue,
        unitType: originalProduct.unitType,
        price: originalProduct.price,
        priceUpdated: false, // Always start with priceUpdated as false
        storeLocation: originalProduct.storeLocation,
        barcode: '', // Clear barcode for the duplicate
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save the duplicated product
      await saveProduct(duplicatedProduct);

      return duplicatedProduct;
    } catch (e) {
      print('Error duplicating product: $e');
      rethrow;
    }
  }
}
