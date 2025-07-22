import '../models/product.dart';

// Enum for different label row content types
enum LabelRowType {
  persianNameWithSize, // product.fullNameFa (persian size)
  englishNameWithSize, // product.fullNameEn (size)
  persianName, // product.nameFa
  englishName, // product.nameEn
  persianBrand, // product.brandFa
  englishBrand, // product.brandEn
  persianNameBrand, // product.nameFa product.brandFa
  englishNameBrand, // product.brandEn product.nameEn
  persianSize, // product.persianSize
  englishSize, // product.size
  price, // $XX.XX
  priceWithUnit, // $XX.XX /unit (lb/kg/ea/etc)
  barcode, // PLU# XXXXX
  customText, // Custom static text
  empty, // Empty row (spacer)
}

// Enum for text alignment
enum LabelTextAlignment { left, center, right }

// Enum for font weight
enum LabelFontWeight { normal, bold }

// Class to define a single row in a label
class LabelRow {
  final LabelRowType type;
  final LabelTextAlignment alignment;
  final LabelFontWeight fontWeight;
  final double fontSize;
  final bool isRTL; // For Persian text direction
  final String? customText; // Used when type is customText
  final bool visible; // Show/hide this row

  const LabelRow({
    required this.type,
    this.alignment = LabelTextAlignment.center,
    this.fontWeight = LabelFontWeight.normal,
    this.fontSize = 12.0,
    this.isRTL = false,
    this.customText,
    this.visible = true,
  });

  // Generate the text content for this row based on the product
  String generateText(Product product) {
    if (!visible) return '';

    switch (type) {
      case LabelRowType.persianNameWithSize:
        return '${product.nameFa} ${product.brandFa} (${product.persianSize})';

      case LabelRowType.englishNameWithSize:
        return '${product.brandEn} ${product.nameEn} (${product.size})';

      case LabelRowType.persianName:
        return product.nameFa;

      case LabelRowType.englishName:
        return product.nameEn;

      case LabelRowType.persianBrand:
        return product.brandFa;

      case LabelRowType.englishBrand:
        return product.brandEn;

      case LabelRowType.persianNameBrand:
        return '${product.nameFa} ${product.brandFa}';

      case LabelRowType.englishNameBrand:
        return '${product.brandEn} ${product.nameEn}';

      case LabelRowType.persianSize:
        return product.persianSize;

      case LabelRowType.englishSize:
        return product.size;

      case LabelRowType.price:
        return '\$${product.price.toStringAsFixed(2)}';

      case LabelRowType.priceWithUnit:
        String unit = _getSellingUnit(product.unitType);
        return '\$${product.price.toStringAsFixed(2)} /$unit';

      case LabelRowType.barcode:
        return product.barcode.isNotEmpty ? 'PLU# ${product.barcode}' : '';

      case LabelRowType.customText:
        return customText ?? '';

      case LabelRowType.empty:
        return '';
    }
  }

  // Helper method to get selling unit string
  String _getSellingUnit(UnitType unitType) {
    switch (unitType) {
      case UnitType.kg:
        return 'kg';
      case UnitType.lb:
        return 'lb';
      case UnitType.gr:
        return '100gr';
      case UnitType.ea:
      case UnitType.piece:
        return 'ea';
      case UnitType.pack:
        return 'pkg';
      case UnitType.pkg:
        return 'kg';
      case UnitType.plb:
        return 'lb';
      case UnitType.phandered:
        return '100gr';
      default:
        return 'ea';
    }
  }

  // Create a copy with modified properties
  LabelRow copyWith({
    LabelRowType? type,
    LabelTextAlignment? alignment,
    LabelFontWeight? fontWeight,
    double? fontSize,
    bool? isRTL,
    String? customText,
    bool? visible,
  }) {
    return LabelRow(
      type: type ?? this.type,
      alignment: alignment ?? this.alignment,
      fontWeight: fontWeight ?? this.fontWeight,
      fontSize: fontSize ?? this.fontSize,
      isRTL: isRTL ?? this.isRTL,
      customText: customText ?? this.customText,
      visible: visible ?? this.visible,
    );
  }

  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'alignment': alignment.index,
      'fontWeight': fontWeight.index,
      'fontSize': fontSize,
      'isRTL': isRTL,
      'customText': customText,
      'visible': visible,
    };
  }

  // Create from map
  factory LabelRow.fromMap(Map<String, dynamic> map) {
    return LabelRow(
      type: LabelRowType.values[map['type'] ?? 0],
      alignment: LabelTextAlignment.values[map['alignment'] ?? 1],
      fontWeight: LabelFontWeight.values[map['fontWeight'] ?? 0],
      fontSize: map['fontSize']?.toDouble() ?? 12.0,
      isRTL: map['isRTL'] ?? false,
      customText: map['customText'],
      visible: map['visible'] ?? true,
    );
  }
}

// Dynamic label template class
class DynamicLabelTemplate {
  final String name;
  final double widthCm;
  final double heightCm;
  final int columnsPerPage;
  final int rowsPerPage;
  final double horizontalSpacingCm;
  final double verticalSpacingCm;
  final double pageMarginTopCm;
  final double pageMarginLeftCm;
  final double pageMarginRightCm;
  final double pageMarginBottomCm;
  final double paddingCm;
  final List<LabelRow> labelRows;

  const DynamicLabelTemplate({
    required this.name,
    required this.widthCm,
    required this.heightCm,
    required this.columnsPerPage,
    required this.rowsPerPage,
    this.horizontalSpacingCm = 0.0,
    this.verticalSpacingCm = 0.0,
    this.pageMarginTopCm = 1.0,
    this.pageMarginLeftCm = 1.0,
    this.pageMarginRightCm = 1.0,
    this.pageMarginBottomCm = 1.0,
    this.paddingCm = 0.1,
    this.labelRows = const [],
  });

  // Convert measurements for PDF (72 points per inch)
  double get widthPoints => cmToPoints(widthCm);
  double get heightPoints => cmToPoints(heightCm);
  double get horizontalSpacingPoints => cmToPoints(horizontalSpacingCm);
  double get verticalSpacingPoints => cmToPoints(verticalSpacingCm);
  double get pageMarginTopPoints => cmToPoints(pageMarginTopCm);
  double get pageMarginLeftPoints => cmToPoints(pageMarginLeftCm);
  double get pageMarginRightPoints => cmToPoints(pageMarginRightCm);
  double get pageMarginBottomPoints => cmToPoints(pageMarginBottomCm);
  double get paddingPoints => cmToPoints(paddingCm);

  // Helper for direct CM to Points conversion (72 points per inch)
  static double cmToPoints(double cm) {
    return cm / 2.54 * 72;
  }

  // Helper for direct CM to Pixels conversion (96 PPI)
  static double cmToPixels(double cm) {
    return cm / 2.54 * 96;
  }

  // Get only visible rows
  List<LabelRow> get visibleRows =>
      labelRows.where((row) => row.visible).toList();

  // Create a copy with modified properties
  DynamicLabelTemplate copyWith({
    String? name,
    double? widthCm,
    double? heightCm,
    int? columnsPerPage,
    int? rowsPerPage,
    double? horizontalSpacingCm,
    double? verticalSpacingCm,
    double? pageMarginTopCm,
    double? pageMarginLeftCm,
    double? pageMarginRightCm,
    double? pageMarginBottomCm,
    double? paddingCm,
    List<LabelRow>? labelRows,
  }) {
    return DynamicLabelTemplate(
      name: name ?? this.name,
      widthCm: widthCm ?? this.widthCm,
      heightCm: heightCm ?? this.heightCm,
      columnsPerPage: columnsPerPage ?? this.columnsPerPage,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      horizontalSpacingCm: horizontalSpacingCm ?? this.horizontalSpacingCm,
      verticalSpacingCm: verticalSpacingCm ?? this.verticalSpacingCm,
      pageMarginTopCm: pageMarginTopCm ?? this.pageMarginTopCm,
      pageMarginLeftCm: pageMarginLeftCm ?? this.pageMarginLeftCm,
      pageMarginRightCm: pageMarginRightCm ?? this.pageMarginRightCm,
      pageMarginBottomCm: pageMarginBottomCm ?? this.pageMarginBottomCm,
      paddingCm: paddingCm ?? this.paddingCm,
      labelRows: labelRows ?? this.labelRows,
    );
  }

  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'widthCm': widthCm,
      'heightCm': heightCm,
      'columnsPerPage': columnsPerPage,
      'rowsPerPage': rowsPerPage,
      'horizontalSpacingCm': horizontalSpacingCm,
      'verticalSpacingCm': verticalSpacingCm,
      'pageMarginTopCm': pageMarginTopCm,
      'pageMarginLeftCm': pageMarginLeftCm,
      'pageMarginRightCm': pageMarginRightCm,
      'pageMarginBottomCm': pageMarginBottomCm,
      'paddingCm': paddingCm,
      'labelRows': labelRows.map((row) => row.toMap()).toList(),
    };
  }

  // Create from map
  factory DynamicLabelTemplate.fromMap(Map<String, dynamic> map) {
    return DynamicLabelTemplate(
      name: map['name'] ?? 'Unnamed Template',
      widthCm: map['widthCm']?.toDouble() ?? 10.0,
      heightCm: map['heightCm']?.toDouble() ?? 3.0,
      columnsPerPage: map['columnsPerPage'] ?? 2,
      rowsPerPage: map['rowsPerPage'] ?? 8,
      horizontalSpacingCm: map['horizontalSpacingCm']?.toDouble() ?? 0.0,
      verticalSpacingCm: map['verticalSpacingCm']?.toDouble() ?? 0.0,
      pageMarginTopCm: map['pageMarginTopCm']?.toDouble() ?? 1.0,
      pageMarginLeftCm: map['pageMarginLeftCm']?.toDouble() ?? 1.0,
      pageMarginRightCm: map['pageMarginRightCm']?.toDouble() ?? 1.0,
      pageMarginBottomCm: map['pageMarginBottomCm']?.toDouble() ?? 1.0,
      paddingCm: map['paddingCm']?.toDouble() ?? 0.1,
      labelRows:
          (map['labelRows'] as List<dynamic>?)
              ?.map((row) => LabelRow.fromMap(row))
              .toList() ??
          [],
    );
  }
}

// Predefined dynamic label templates
class DynamicLabelTemplates {
  // Standard bilingual template with your requested layout
  static const DynamicLabelTemplate standard = DynamicLabelTemplate(
    name: "Standard Bilingual (10x3cm)",
    widthCm: 10.0,
    heightCm: 3.0,
    columnsPerPage: 2,
    rowsPerPage: 8,
    horizontalSpacingCm: 0.19,
    verticalSpacingCm: 0.18,
    pageMarginTopCm: 1.0,
    pageMarginLeftCm: 0.7,
    pageMarginRightCm: 0.7,
    pageMarginBottomCm: 1.0,
    paddingCm: 0.15,
    labelRows: [
      LabelRow(
        type: LabelRowType.persianNameWithSize,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.bold,
        fontSize: 14.0,
        isRTL: true,
      ),
      LabelRow(
        type: LabelRowType.englishNameWithSize,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.normal,
        fontSize: 12.0,
        isRTL: false,
      ),
      LabelRow(
        type: LabelRowType.priceWithUnit,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.bold,
        fontSize: 16.0,
        isRTL: false,
      ),
      LabelRow(
        type: LabelRowType.barcode,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.normal,
        fontSize: 10.0,
        isRTL: false,
      ),
    ],
  );

  // Compact 3-column template
  static const DynamicLabelTemplate compact3Column = DynamicLabelTemplate(
    name: "Compact 3-Column (6.5x2cm)",
    widthCm: 6.5,
    heightCm: 2.0,
    columnsPerPage: 3,
    rowsPerPage: 12,
    horizontalSpacingCm: 0.15,
    verticalSpacingCm: 0.1,
    pageMarginTopCm: 0.7,
    pageMarginLeftCm: 0.5,
    pageMarginRightCm: 0.5,
    pageMarginBottomCm: 0.7,
    paddingCm: 0.08,
    labelRows: [
      LabelRow(
        type: LabelRowType.persianName,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.bold,
        fontSize: 10.0,
        isRTL: true,
      ),
      LabelRow(
        type: LabelRowType.englishNameBrand,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.normal,
        fontSize: 8.0,
        isRTL: false,
      ),
      LabelRow(
        type: LabelRowType.price,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.bold,
        fontSize: 12.0,
        isRTL: false,
      ),
    ],
  );

  // Avery 5160 compatible template
  static const DynamicLabelTemplate avery5160 = DynamicLabelTemplate(
    name: "Avery 5160 Compatible",
    widthCm: 6.67,
    heightCm: 2.54,
    columnsPerPage: 3,
    rowsPerPage: 10,
    horizontalSpacingCm: 0.3,
    verticalSpacingCm: 0.0,
    pageMarginTopCm: 1.27,
    pageMarginLeftCm: 0.46,
    pageMarginRightCm: 0.46,
    pageMarginBottomCm: 1.27,
    paddingCm: 0.1,
    labelRows: [
      LabelRow(
        type: LabelRowType.persianNameBrand,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.bold,
        fontSize: 9.0,
        isRTL: true,
      ),
      LabelRow(
        type: LabelRowType.englishNameBrand,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.normal,
        fontSize: 8.0,
        isRTL: false,
      ),
      LabelRow(
        type: LabelRowType.priceWithUnit,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.bold,
        fontSize: 11.0,
        isRTL: false,
      ),
      LabelRow(
        type: LabelRowType.barcode,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.normal,
        fontSize: 7.0,
        isRTL: false,
      ),
    ],
  );

  // Price-focused template
  static const DynamicLabelTemplate priceFocus = DynamicLabelTemplate(
    name: "Price Focus (10x3cm)",
    widthCm: 10.0,
    heightCm: 3.0,
    columnsPerPage: 2,
    rowsPerPage: 8,
    horizontalSpacingCm: 0.19,
    verticalSpacingCm: 0.18,
    pageMarginTopCm: 1.0,
    pageMarginLeftCm: 0.7,
    pageMarginRightCm: 0.7,
    pageMarginBottomCm: 1.0,
    paddingCm: 0.15,
    labelRows: [
      LabelRow(
        type: LabelRowType.persianName,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.bold,
        fontSize: 12.0,
        isRTL: true,
      ),
      LabelRow(
        type: LabelRowType.priceWithUnit,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.bold,
        fontSize: 20.0,
        isRTL: false,
      ),
      LabelRow(
        type: LabelRowType.barcode,
        alignment: LabelTextAlignment.center,
        fontWeight: LabelFontWeight.normal,
        fontSize: 10.0,
        isRTL: false,
      ),
    ],
  );

  // Get all predefined templates
  static List<DynamicLabelTemplate> get allTemplates => [
    standard,
    compact3Column,
    avery5160,
    priceFocus,
  ];
}
