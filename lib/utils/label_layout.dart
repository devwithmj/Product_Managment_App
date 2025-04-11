import 'package:flutter/material.dart';
import '../models/label_template.dart';
import '../models/product.dart';

class LabelLayout {
  // Calculate positions for labels on a page for PDF (using points)
  static List<Rect> calculateLabelPositionsForPDF(LabelSize labelSize) {
    List<Rect> positions = [];

    double startX = labelSize.pageMarginLeftPoints;
    double startY = labelSize.pageMarginTopPoints;

    // Calculate available space on the page (in points)
    double availableWidth =
        LabelSize.letterWidthPoints -
        labelSize.pageMarginLeftPoints -
        labelSize.pageMarginRightPoints;
    double availableHeight =
        LabelSize.letterHeightPoints -
        labelSize.pageMarginTopPoints -
        labelSize.pageMarginBottomPoints;

    // Calculate actual label position and size
    double labelSpaceWidth = availableWidth / labelSize.columnsPerPage;
    double labelSpaceHeight = availableHeight / labelSize.rowsPerPage;

    double labelWidth = labelSpaceWidth - labelSize.horizontalSpacingPoints;
    double labelHeight = labelSpaceHeight - labelSize.verticalSpacingPoints;

    for (int row = 0; row < labelSize.rowsPerPage; row++) {
      for (int col = 0; col < labelSize.columnsPerPage; col++) {
        double x = startX + col * labelSpaceWidth;
        double y = startY + row * labelSpaceHeight;

        positions.add(Rect.fromLTWH(x, y, labelWidth, labelHeight));
      }
    }

    return positions;
  }

  // Calculate positions for labels on a page (using pixels for screen display)
  static List<Rect> calculateLabelPositions(LabelSize labelSize) {
    List<Rect> positions = [];

    // Convert cm to pixels for display
    double startX = LabelSize.cmToPixels(labelSize.pageMarginLeftCm);
    double startY = LabelSize.cmToPixels(labelSize.pageMarginTopCm);

    // Available space
    double availableWidth = LabelSize.cmToPixels(
      LabelSize.letterWidthCm -
          labelSize.pageMarginLeftCm -
          labelSize.pageMarginRightCm,
    );
    double availableHeight = LabelSize.cmToPixels(
      LabelSize.letterHeightCm -
          labelSize.pageMarginTopCm -
          labelSize.pageMarginBottomCm,
    );

    // Calculate individual label positions
    double labelSpaceWidth = availableWidth / labelSize.columnsPerPage;
    double labelSpaceHeight = availableHeight / labelSize.rowsPerPage;

    double labelWidth =
        labelSpaceWidth - LabelSize.cmToPixels(labelSize.horizontalSpacingCm);
    double labelHeight =
        labelSpaceHeight - LabelSize.cmToPixels(labelSize.verticalSpacingCm);

    for (int row = 0; row < labelSize.rowsPerPage; row++) {
      for (int col = 0; col < labelSize.columnsPerPage; col++) {
        double x = startX + col * labelSpaceWidth;
        double y = startY + row * labelSpaceHeight;

        positions.add(Rect.fromLTWH(x, y, labelWidth, labelHeight));
      }
    }

    print(
      "Label size: ${labelWidth}px × ${labelHeight}px (${LabelSize.cmToPixels(labelSize.widthCm)}px × ${LabelSize.cmToPixels(labelSize.heightCm)}px expected)",
    );

    return positions;
  }

  // Calculate how many pages will be needed for the selected products
  static int calculatePageCount(int productCount, LabelSize labelSize) {
    int labelsPerPage = labelSize.rowsPerPage * labelSize.columnsPerPage;
    return (productCount / labelsPerPage).ceil();
  }

  // Organize products into pages
  static List<List<Product>> organizeProductsIntoPages(
    List<Product> products,
    LabelSize labelSize,
  ) {
    List<List<Product>> pages = [];
    int labelsPerPage = labelSize.rowsPerPage * labelSize.columnsPerPage;

    for (int i = 0; i < products.length; i += labelsPerPage) {
      int end =
          (i + labelsPerPage < products.length)
              ? i + labelsPerPage
              : products.length;
      pages.add(products.sublist(i, end));
    }

    return pages;
  }
}
