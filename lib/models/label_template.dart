class LabelSize {
  final String name;
  final double widthCm;
  final double heightCm;

  // Number of labels that fit on a letter page
  final int columnsPerPage;
  final int rowsPerPage;

  // Margins and spacing in cm
  final double horizontalSpacingCm;
  final double verticalSpacingCm;
  final double pageMarginTopCm;
  final double pageMarginLeftCm;
  final double pageMarginRightCm;
  final double pageMarginBottomCm;

  // Font sizes
  final double englishFontSize;
  final double persianFontSize;
  final double priceFontSize;

  const LabelSize({
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
    this.englishFontSize = 14.0,
    this.persianFontSize = 18.0,
    this.priceFontSize = 26.0,
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

  // Convert to inches (for PDF)
  double get widthInches => widthCm / 2.54;
  double get heightInches => heightCm / 2.54;

  // Helper for direct CM to Points conversion (72 points per inch)
  static double cmToPoints(double cm) {
    return cm / 2.54 * 72; // Convert cm to inches, then inches to points
  }

  // Helper for direct CM to Pixels conversion (96 PPI)
  static double cmToPixels(double cm) {
    return cm / 2.54 * 96; // Convert cm to inches, then inches to pixels
  }

  // Standard letter page size in cm
  static const double letterWidthCm = 21.59; // 8.5 inches
  static const double letterHeightCm = 27.94; // 11 inches

  // Letter page in points (for PDF)
  static final double letterWidthPoints = cmToPoints(letterWidthCm);
  static final double letterHeightPoints = cmToPoints(letterHeightCm);

  // Letter page in pixels (for UI)
  static final double letterWidthPixels = cmToPixels(letterWidthCm);
  static final double letterHeightPixels = cmToPixels(letterHeightCm);
}

// Define label templates with corrected measurements and font sizes
class LabelTemplates {
  // Accurate 3 x 10 cm labels (on US Letter paper)
  static const LabelSize standard = LabelSize(
    name: "3 x 10 cm Label",
    widthCm: 10.0, // 10 cm width
    heightCm: 3.0, // 3 cm height
    columnsPerPage: 2, // 2 labels per row
    rowsPerPage: 8, // 8 rows of labels per page (adjusted for better fit)
    horizontalSpacingCm: 0.19, // Reduced spacing between columns for better fit
    verticalSpacingCm: 0.18, // Reduced spacing between rows
    pageMarginTopCm: 1.0, // Top margin
    pageMarginLeftCm: 0.7, // Slightly reduced left margin
    pageMarginRightCm: 0.7, // Slightly reduced right margin
    pageMarginBottomCm: 1.0, // Bottom margin
    englishFontSize: 14.0,
    persianFontSize: 18.0,
    priceFontSize: 26.0,
  );

  // Small 2 x 10 cm label template with tighter fit and smaller fonts
  static const LabelSize smallTight = LabelSize(
    name: "2.5 x 10 cm Label",
    widthCm: 10.0,
    heightCm: 2.5, // Smaller height (2 cm)
    columnsPerPage: 3,
    rowsPerPage: 10, // More rows per page due to smaller height
    horizontalSpacingCm: 0.19,
    verticalSpacingCm: 0.1, // Minimal spacing
    pageMarginTopCm: 0.7, // Smaller margins
    pageMarginLeftCm: 0.7,
    pageMarginRightCm: 0.7,
    pageMarginBottomCm: 0.7,
    englishFontSize: 10.0, // Smaller font sizes for smaller label
    persianFontSize: 12.0,
    priceFontSize: 18.0,
  );

  // Small 2 x 6.5 cm label template with 3 columns
  static const LabelSize small3Column = LabelSize(
    name: "2 x 6.5 cm (3-Column)",
    widthCm: 6.5, // Narrower width to fit 3 columns (6.5 cm)
    heightCm: 2.0, // Smaller height (2 cm)
    columnsPerPage: 3, // 3 labels per row
    rowsPerPage: 12, // 12 rows of labels per page
    horizontalSpacingCm: 0.15, // Tighter horizontal spacing
    verticalSpacingCm: 0.1, // Minimal vertical spacing
    pageMarginTopCm: 0.7,
    pageMarginLeftCm: 0.5, // Reduced margin to fit 3 columns
    pageMarginRightCm: 0.5, // Reduced margin to fit 3 columns
    pageMarginBottomCm: 0.7,
    englishFontSize: 8.0, // Even smaller fonts for narrower label
    persianFontSize: 10.0,
    priceFontSize: 16.0,
  );

  // Alternative 3 x 10 cm template with tighter fit
  static const LabelSize standardTight = LabelSize(
    name: "3 x 10 cm Tight",
    widthCm: 10.0,
    heightCm: 3.0,
    columnsPerPage: 2,
    rowsPerPage: 9, // More rows per page with tighter spacing
    horizontalSpacingCm: 0.19,
    verticalSpacingCm: 0.1, // Minimal spacing
    pageMarginTopCm: 0.7, // Smaller margins
    pageMarginLeftCm: 0.7,
    pageMarginRightCm: 0.7,
    pageMarginBottomCm: 0.7,
    englishFontSize: 14.0,
    persianFontSize: 18.0,
    priceFontSize: 26.0,
  );

  // Avery 5160 Easy Peel Address Labels (2.625" x 1" = 6.67cm x 2.54cm)
  // Standard 30 labels per sheet (3 columns x 10 rows)
  static const LabelSize avery5160 = LabelSize(
    name: "Avery",
    widthCm: 6.67, // 2.625 inches = 6.67 cm
    heightCm: 2.54, // 1 inch = 2.54 cm
    columnsPerPage: 3, // 3 labels per row
    rowsPerPage: 10, // 10 rows of labels per page
    horizontalSpacingCm: 0.3, // Slightly reduced spacing between columns
    verticalSpacingCm: 0.0, // No spacing between rows (labels are touching)
    pageMarginTopCm: 1.27, // 0.5" top margin
    pageMarginLeftCm: 0.46, // Adjusted for proper fit
    pageMarginRightCm: 0.46, // Adjusted for proper fit
    pageMarginBottomCm: 1.27, // 0.5" bottom margin
    englishFontSize: 9.0, // Smaller font for compact labels
    persianFontSize: 11.0, // Slightly larger for Persian readability
    priceFontSize: 14.0, // Compact price display
  );

  // Add a list of all available label sizes
  static List<LabelSize> get allSizes => [
    standard,
    standardTight,
    smallTight,
    small3Column,
    avery5160,
  ];

  // Check if a label size is for thermal printing (legacy function, always returns false)
  static bool isThermalSize(LabelSize labelSize) {
    return false;
  }
}
