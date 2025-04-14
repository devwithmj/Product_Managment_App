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
  final double priceFontSize;
  final double persianFontSize;
  final double englishFontSize;

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

// Define only the 3.5 x 10 cm label
class LabelTemplates {
  // Exact 3.5 x 10 cm labels (on US Letter paper)
  static const LabelSize standard = LabelSize(
    name: "3 x 10 cm Label",
    widthCm: 10.0, // 10 cm width
    heightCm: 3, // 3.5 cm height
    columnsPerPage: 2, // 2 labels per row
    rowsPerPage: 7, // 7 rows of labels per page
    horizontalSpacingCm: 0.2, // Small gap between columns
    verticalSpacingCm: 0.2, // Small gap between rows
    pageMarginTopCm: 1.0, // Top margin
    pageMarginLeftCm: 0.8, // Left margin
    pageMarginRightCm: 0.8, // Right margin
    pageMarginBottomCm: 1.0, // Bottom margin
  );
  static const LabelSize fridge = LabelSize(
    name: "2 x 10 cm Label",
    widthCm: 10.0, // 10 cm width
    heightCm: 2, // 2.0 cm height
    columnsPerPage: 2, // 2 labels per row
    rowsPerPage: 11, // 7 rows of labels per page
    horizontalSpacingCm: 0.1, // Small gap between columns
    verticalSpacingCm: 0.1, // Small gap between rows
    pageMarginTopCm: 1.0, // Top margin
    pageMarginLeftCm: 0.5, // Left margin
    pageMarginRightCm: 0.5, // Right margin
    pageMarginBottomCm: 1.0, // Bottom margin
    priceFontSize: 18.0,
    persianFontSize: 14.0,
    englishFontSize: 12.0,
  );
  static List<LabelSize> get allSizes => [standard, fridge];
}
