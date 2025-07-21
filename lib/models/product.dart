import 'dart:convert';

import 'package:product_app/utils/number_formatter.dart';

enum StoreLocation { downtown, uptown, both }

// Define unit types for weight and volume
enum UnitType {
  gr,
  kg,
  ml,
  l,
  piece,
  pack,
  box,
  other,
  lb,
  pkg,
  plb,
  phandered,
  ea,
}

// Label customization options
class LabelOptions {
  final bool showPrice;
  final bool showSize;
  final bool showBarcode; // Changed from showPLU to showBarcode
  final bool showEnglishName;
  final bool showPersianName;
  final bool showBrand;

  const LabelOptions({
    this.showPrice = true,
    this.showSize = true,
    this.showBarcode =
        true, // Changed default to true so barcode shows by default
    this.showEnglishName = true,
    this.showPersianName = true,
    this.showBrand = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'showPrice': showPrice ? 1 : 0,
      'showSize': showSize ? 1 : 0,
      'showBarcode': showBarcode ? 1 : 0, // Changed from showPLU
      'showEnglishName': showEnglishName ? 1 : 0,
      'showPersianName': showPersianName ? 1 : 0,
      'showBrand': showBrand ? 1 : 0,
    };
  }

  factory LabelOptions.fromMap(Map<String, dynamic> map) {
    return LabelOptions(
      showPrice: (map['showPrice'] ?? 1) == 1,
      showSize: (map['showSize'] ?? 1) == 1,
      showBarcode:
          (map['showBarcode'] ?? map['showPLU'] ?? 1) ==
          1, // Support both old and new field names, default to true
      showEnglishName: (map['showEnglishName'] ?? 1) == 1,
      showPersianName: (map['showPersianName'] ?? 1) == 1,
      showBrand: (map['showBrand'] ?? 1) == 1,
    );
  }

  LabelOptions copyWith({
    bool? showPrice,
    bool? showSize,
    bool? showBarcode, // Changed from showPLU
    bool? showEnglishName,
    bool? showPersianName,
    bool? showBrand,
  }) {
    return LabelOptions(
      showPrice: showPrice ?? this.showPrice,
      showSize: showSize ?? this.showSize,
      showBarcode: showBarcode ?? this.showBarcode, // Changed from showPLU
      showEnglishName: showEnglishName ?? this.showEnglishName,
      showPersianName: showPersianName ?? this.showPersianName,
      showBrand: showBrand ?? this.showBrand,
    );
  }
}

class Product {
  final String id;
  String nameEn;
  String nameFa;
  String brandEn;
  String brandFa;
  String sizeValue; // Numeric value for size/weight
  UnitType unitType; // Unit type (gr, kg, ml, etc.)
  double price;
  bool priceUpdated;
  StoreLocation storeLocation;
  String barcode;
  LabelOptions labelOptions; // Custom label display options
  DateTime createdAt;
  DateTime updatedAt;

  // Getter for formatted size (combines sizeValue and unitType)
  String get size => '$sizeValue ${getUnitTypeString(unitType)}';
  String get persianSize =>
      '${NumberFormatter.convertToPersianNumber(sizeValue)}${getUnitTypeStringFa(unitType)}';
  String get fullNameFa => '$nameFa $brandFa ($persianSize)';
  String get fullNameEn => '$brandEn $nameEn ($size)';

  // Validate barcode format (for PLU use, 2-5 digits)
  bool get isValidPLU =>
      barcode.isEmpty ||
      (barcode.length >= 2 &&
          barcode.length <= 5 &&
          int.tryParse(barcode) != null);

  Product({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    required this.brandEn,
    required this.brandFa,
    this.sizeValue = '',
    required this.unitType,
    required this.price,
    this.priceUpdated = false,
    this.storeLocation = StoreLocation.both,
    this.barcode = '',
    this.labelOptions = const LabelOptions(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Create a copy of the product with optional new values
  Product copyWith({
    String? nameEn,
    String? nameFa,
    String? brandEn,
    String? brandFa,
    String? sizeValue,
    UnitType? unitType,
    double? price,
    bool? priceUpdated,
    StoreLocation? storeLocation,
    String? barcode,
    LabelOptions? labelOptions,
    DateTime? updatedAt,
  }) {
    // If price is changing, automatically set priceUpdated to true
    final bool isPriceUpdated =
        (price != null && price != this.price)
            ? true
            : (priceUpdated ?? this.priceUpdated);

    return Product(
      id: id,
      nameEn: nameEn ?? this.nameEn,
      nameFa: nameFa ?? this.nameFa,
      brandEn: brandEn ?? this.brandEn,
      brandFa: brandFa ?? this.brandFa,
      sizeValue: sizeValue ?? this.sizeValue,
      unitType: unitType ?? this.unitType,
      price: price ?? this.price,
      priceUpdated: isPriceUpdated,
      storeLocation: storeLocation ?? this.storeLocation,
      barcode: barcode ?? this.barcode,
      labelOptions: labelOptions ?? this.labelOptions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convert Product to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameFa': nameFa,
      'brandEn': brandEn,
      'brandFa': brandFa,
      'sizeValue': sizeValue,
      'unitType': unitType.index,
      'price': price,
      'priceUpdated': priceUpdated ? 1 : 0, // Convert bool to int for SQLite
      'storeLocation': storeLocation.index,
      'barcode': barcode,
      ...labelOptions.toMap(), // Spread the label options into the map
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create Product from Map (database retrieval)
  factory Product.fromMap(Map<String, dynamic> map) {
    // Handle both bool and int for priceUpdated field
    bool isPriceUpdated;

    // If it's already a bool, use it directly
    if (map['priceUpdated'] is bool) {
      isPriceUpdated = map['priceUpdated'];
    }
    // If it's an int, convert it (1 = true, 0 = false)
    else if (map['priceUpdated'] is int) {
      isPriceUpdated = map['priceUpdated'] == 1;
    }
    // Default to false for any other case
    else {
      isPriceUpdated = false;
    }

    // Handle unit type field
    UnitType unit;
    try {
      // Try to parse the unit type from the index
      int unitIndex = map['unitType'] ?? 0;
      unit = UnitType.values[unitIndex];
    } catch (e) {
      // Default to grams if there's an error
      unit = UnitType.gr;
    }

    // Parse timestamps or use current time as fallback
    DateTime createdAt, updatedAt;
    try {
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      );
      updatedAt = DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      createdAt = DateTime.now();
      updatedAt = DateTime.now();
    }

    // Parse label options
    LabelOptions labelOptions;
    try {
      labelOptions = LabelOptions.fromMap(map);
    } catch (e) {
      labelOptions = const LabelOptions();
    }

    return Product(
      id: map['id'],
      nameEn: map['nameEn'],
      nameFa: map['nameFa'],
      brandEn: map['brandEn'],
      brandFa: map['brandFa'],
      sizeValue: map['sizeValue'] ?? '',
      unitType: unit,
      price:
          map['price'] is int ? (map['price'] as int).toDouble() : map['price'],
      priceUpdated: isPriceUpdated,
      storeLocation: StoreLocation.values[map['storeLocation']],
      barcode: map['barcode'] ?? '',
      labelOptions: labelOptions,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Convert to JSON string
  String toJson() => json.encode(toMap());

  // Create from JSON string
  factory Product.fromJson(String source) =>
      Product.fromMap(json.decode(source));

  // Helper to get string representation of UnitType
  static String getUnitTypeString(UnitType unit) {
    switch (unit) {
      case UnitType.gr:
        return 'gr';
      case UnitType.kg:
        return 'kg';
      case UnitType.ml:
        return 'ml';
      case UnitType.l:
        return 'L';
      case UnitType.piece:
        return 'pc';
      case UnitType.pack:
        return 'pack';
      case UnitType.box:
        return 'box';
      case UnitType.lb:
        return 'lb';
      case UnitType.pkg:
        return '/kg';
      case UnitType.plb:
        return '/lb';
      case UnitType.phandered:
        return '/100gr';
      case UnitType.ea:
        return 'ea';
      case UnitType.other:
        return 'other';
    }
  }

  // Helper to get all UnitType options as strings
  static List<String> get unitTypeStrings =>
      UnitType.values.map((unit) => getUnitTypeString(unit)).toList();

  @override
  String toString() {
    return 'Product(id: $id, nameEn: $nameEn, nameFa: $nameFa, brandEn: $brandEn, '
        'brandFa: $brandFa, size: $size, price: $price, '
        'priceUpdated: $priceUpdated, storeLocation: $storeLocation, barcode: $barcode, '
        'labelOptions: $labelOptions)';
  }
}

getUnitTypeStringFa(UnitType unit) {
  switch (unit) {
    case UnitType.gr:
      return 'گرم';
    case UnitType.kg:
      return 'کیلو';
    case UnitType.ml:
      return 'میل';
    case UnitType.l:
      return 'لیتر';
    case UnitType.piece:
      return 'عدد';
    case UnitType.pack:
      return 'بسته';
    case UnitType.box:
      return 'جعبه';
    case UnitType.lb:
      return 'پوند';
    case UnitType.pkg:
      return '/کیلو';
    case UnitType.plb:
      return '/پوند';
    case UnitType.phandered:
      return '/100گرم';
    case UnitType.ea:
      return 'عدد';
    case UnitType.other:
      return 'Other';
  }
}
