// This utility function can be added to your project to verify
// that label dimensions actually fit on the page as intended

import '../models/label_template.dart';

class LabelArrangementHelper {
  /// Validates that a label arrangement fits on a US Letter page
  /// and returns details about the layout
  static Map<String, dynamic> validateLabelArrangement(LabelSize labelSize) {
    final Map<String, dynamic> result = {};

    // Letter page dimensions
    final double letterWidthCm = LabelSize.letterWidthCm;
    final double letterHeightCm = LabelSize.letterHeightCm;

    // Calculate total width required
    final double totalWidthRequired =
        (labelSize.widthCm * labelSize.columnsPerPage) +
        (labelSize.horizontalSpacingCm * (labelSize.columnsPerPage - 1)) +
        labelSize.pageMarginLeftCm +
        labelSize.pageMarginRightCm;

    // Calculate total height required
    final double totalHeightRequired =
        (labelSize.heightCm * labelSize.rowsPerPage) +
        (labelSize.verticalSpacingCm * (labelSize.rowsPerPage - 1)) +
        labelSize.pageMarginTopCm +
        labelSize.pageMarginBottomCm;

    // Check if the arrangement fits
    final bool widthFits = totalWidthRequired <= letterWidthCm;
    final bool heightFits = totalHeightRequired <= letterHeightCm;
    final bool fitsOnPage = widthFits && heightFits;

    // Calculate remaining space
    final double remainingWidthCm = letterWidthCm - totalWidthRequired;
    final double remainingHeightCm = letterHeightCm - totalHeightRequired;

    // Calculate labels per page
    final int labelsPerPage = labelSize.columnsPerPage * labelSize.rowsPerPage;

    // Populate result
    result['name'] = labelSize.name;
    result['dimensions'] = '${labelSize.widthCm} x ${labelSize.heightCm} cm';
    result['layout'] =
        '${labelSize.columnsPerPage} columns × ${labelSize.rowsPerPage} rows';
    result['totalWidthRequired'] = totalWidthRequired;
    result['totalHeightRequired'] = totalHeightRequired;
    result['widthFits'] = widthFits;
    result['heightFits'] = heightFits;
    result['fitsOnPage'] = fitsOnPage;
    result['remainingWidthCm'] = remainingWidthCm;
    result['remainingHeightCm'] = remainingHeightCm;
    result['labelsPerPage'] = labelsPerPage;

    return result;
  }

  /// Prints a validation report for a label arrangement
  static void printValidationReport(LabelSize labelSize) {
    final report = validateLabelArrangement(labelSize);

    print('----------------------------------------');
    print('LABEL ARRANGEMENT VALIDATION: ${report['name']}');
    print('----------------------------------------');
    print('Dimensions: ${report['dimensions']}');
    print('Layout: ${report['layout']}');
    print('Labels per page: ${report['labelsPerPage']}');
    print('');
    print(
      'Required width: ${report['totalWidthRequired'].toStringAsFixed(2)} cm (Letter: ${LabelSize.letterWidthCm} cm)',
    );
    print(
      'Required height: ${report['totalHeightRequired'].toStringAsFixed(2)} cm (Letter: ${LabelSize.letterHeightCm} cm)',
    );
    print('');
    print(
      'Fits width: ${report['widthFits'] ? '✅' : '❌'} (${report['remainingWidthCm'].toStringAsFixed(2)} cm remaining)',
    );
    print(
      'Fits height: ${report['heightFits'] ? '✅' : '❌'} (${report['remainingHeightCm'].toStringAsFixed(2)} cm remaining)',
    );
    print(
      'OVERALL: ${report['fitsOnPage'] ? '✅ FITS ON PAGE' : '❌ DOES NOT FIT'}',
    );
    print('----------------------------------------');
  }

  /// Validate all registered label templates
  static void validateAllTemplates() {
    for (final template in LabelTemplates.allSizes) {
      printValidationReport(template);
    }
  }
}
