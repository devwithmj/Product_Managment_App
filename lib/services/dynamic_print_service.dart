import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

import '../models/product.dart';
import '../models/dynamic_label_template.dart';
import '../screens/print_preview_screen.dart';

class DynamicPrintService {
  // Load the Vazirmatn font as a global variable
  static pw.Font? _vazirFont;
  static pw.Font? _vazirFontBold;
  static bool _fontsLoaded = false;

  // Load the fonts from assets
  static Future<void> _loadFonts() async {
    if (_fontsLoaded) return;

    try {
      // Regular font
      final regularFontData = await rootBundle.load(
        'assets/fonts/Vazirmatn-Regular.ttf',
      );
      _vazirFont = pw.Font.ttf(regularFontData);

      // Bold font
      final boldFontData = await rootBundle.load(
        'assets/fonts/Vazirmatn-Bold.ttf',
      );
      _vazirFontBold = pw.Font.ttf(boldFontData);

      _fontsLoaded = true;
      if (kDebugMode) {
        print('Fonts loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading fonts: $e');
      }
      // Fallback to default fonts
      _fontsLoaded = true;
    }
  }

  // Generate a PDF document for printing using dynamic template
  static Future<Uint8List> generatePdf({
    required List<Product> products,
    required DynamicLabelTemplate template,
  }) async {
    // Debug: Print product information
    print(
      'DEBUG: Generating PDF for ${products.length} products using template: ${template.name}',
    );
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      print(
        'DEBUG: Product $i - name: ${product.nameEn}, barcode: "${product.barcode}"',
      );
    }

    // Load fonts first
    await _loadFonts();

    // Create a PDF theme with Vazirmatn font
    final theme = pw.ThemeData.withFont(
      base: _vazirFont ?? pw.Font.helvetica(),
      bold: _vazirFontBold ?? pw.Font.helveticaBold(),
    );

    // Create PDF document with letter size
    final pdf = pw.Document(theme: theme);

    // Calculate exact letter paper size in PDF points
    final pageFormat = PdfPageFormat(
      DynamicLabelTemplate.cmToPoints(21.59), // Letter width
      DynamicLabelTemplate.cmToPoints(27.94), // Letter height
    );

    if (products.isEmpty) {
      // Handle empty product list with a blank page
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text('No products selected for printing'),
            );
          },
        ),
      );
      return pdf.save();
    }

    // Organize products into pages
    final labelsPerPage = template.columnsPerPage * template.rowsPerPage;
    final List<List<Product>> pages = [];

    for (int i = 0; i < products.length; i += labelsPerPage) {
      int end = i + labelsPerPage;
      if (end > products.length) end = products.length;
      pages.add(products.sublist(i, end));
    }

    if (kDebugMode) {
      // Debug information
      print("PDF page size: ${pageFormat.width}pt × ${pageFormat.height}pt");
      print("Labels per page: $labelsPerPage");
      print("Total pages: ${pages.length}");
      print("Label dimensions: ${template.widthCm}cm × ${template.heightCm}cm");
      print(
        "Template: ${template.name} with ${template.visibleRows.length} visible rows",
      );
    }

    // For each page of products
    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final pageProducts = pages[pageIndex];

      // Skip empty pages
      if (pageProducts.isEmpty) continue;

      // Calculate positions for labels on this page using PDF points
      final positions = _calculateLabelPositions(template);

      // Make sure we don't go beyond the available positions
      final count =
          pageProducts.length < positions.length
              ? pageProducts.length
              : positions.length;

      // Add page to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            // Create content for the page
            return pw.Stack(
              children: List.generate(count, (i) {
                final product = pageProducts[i];
                final position = positions[i];

                // Debug information for label position
                if (kDebugMode) {
                  print(
                    "Label $i position: left=${position.left}pt, top=${position.top}pt, width=${position.width}pt, height=${position.height}pt",
                  );
                }

                return _buildDynamicLabel(product, position, template);
              }),
            );
          },
        ),
      );
    }

    // Save PDF to temporary file for debugging
    _savePdfToFile(pdf);

    return pdf.save();
  }

  // Calculate label positions on the page
  static List<Rect> _calculateLabelPositions(DynamicLabelTemplate template) {
    final List<Rect> positions = [];

    final double startX = template.pageMarginLeftPoints;
    final double startY = template.pageMarginTopPoints;
    final double labelWidth = template.widthPoints;
    final double labelHeight = template.heightPoints;
    final double horizontalSpacing = template.horizontalSpacingPoints;
    final double verticalSpacing = template.verticalSpacingPoints;

    for (int row = 0; row < template.rowsPerPage; row++) {
      for (int col = 0; col < template.columnsPerPage; col++) {
        final double x = startX + (col * (labelWidth + horizontalSpacing));
        final double y = startY + (row * (labelHeight + verticalSpacing));

        positions.add(Rect.fromLTWH(x, y, labelWidth, labelHeight));
      }
    }

    return positions;
  }

  // Build a dynamic label using the template configuration
  static pw.Widget _buildDynamicLabel(
    Product product,
    Rect position,
    DynamicLabelTemplate template,
  ) {
    final visibleRows = template.visibleRows;

    return pw.Positioned(
      left: position.left,
      top: position.top,
      child: pw.Container(
        width: position.width,
        height: position.height,
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        padding: pw.EdgeInsets.all(template.paddingPoints),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children:
              visibleRows.map((row) {
                final text = row.generateText(product);

                // Skip empty rows
                if (text.isEmpty) {
                  return pw.SizedBox(height: row.fontSize * 0.5);
                }

                // Create the text widget
                pw.Widget textWidget = pw.Text(
                  text,
                  style: pw.TextStyle(
                    font: row.isRTL ? _vazirFontBold : null,
                    fontSize: row.fontSize * 0.8, // Adjust for PDF scaling
                    fontWeight:
                        row.fontWeight == LabelFontWeight.bold
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                  ),
                  textAlign: _getPdfTextAlignment(row.alignment),
                );

                // Wrap in RTL direction if needed
                if (row.isRTL) {
                  textWidget = pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: textWidget,
                  );
                }

                // Handle special formatting for price rows
                if (row.type == LabelRowType.price ||
                    row.type == LabelRowType.priceWithUnit) {
                  return _buildPriceRow(product, row);
                }

                return textWidget;
              }).toList(),
        ),
      ),
    );
  }

  // Build a special price row with proper formatting
  static pw.Widget _buildPriceRow(Product product, LabelRow row) {
    if (row.type == LabelRowType.price) {
      return _buildStyledPriceDisplay(product.price, row.fontSize);
    } else if (row.type == LabelRowType.priceWithUnit) {
      String unit = _getSellingUnit(product.unitType);
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          _buildStyledPriceDisplay(product.price, row.fontSize),
          pw.SizedBox(width: 4),
          pw.Text(
            '/$unit',
            style: pw.TextStyle(
              fontSize: row.fontSize * 0.6,
              fontWeight:
                  row.fontWeight == LabelFontWeight.bold
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return pw.Text('');
  }

  // Build styled price display with dollars and cents
  static pw.Widget _buildStyledPriceDisplay(double price, double fontSize) {
    final dollars = price.floor();
    final cents = ((price - dollars) * 100).round();

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '\$$dollars.',
          style: pw.TextStyle(
            fontSize: fontSize * 0.8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          cents.toString().padLeft(2, '0'),
          style: pw.TextStyle(
            fontSize: fontSize * 0.6,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Convert alignment enum to PDF text alignment
  static pw.TextAlign _getPdfTextAlignment(LabelTextAlignment alignment) {
    switch (alignment) {
      case LabelTextAlignment.left:
        return pw.TextAlign.left;
      case LabelTextAlignment.center:
        return pw.TextAlign.center;
      case LabelTextAlignment.right:
        return pw.TextAlign.right;
    }
  }

  // Helper method to get selling unit string
  static String _getSellingUnit(UnitType unitType) {
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

  // Save PDF to temporary file (for debugging)
  static Future<void> _savePdfToFile(pw.Document pdf) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/debug_dynamic_labels.pdf');
      await file.writeAsBytes(await pdf.save());
      if (kDebugMode) {
        print('Debug PDF saved to: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Could not save debug PDF: $e');
      }
    }
  }

  // Print the generated PDF
  static Future<void> printPdf(Uint8List pdfBytes) async {
    if (pdfBytes.isEmpty) {
      throw Exception('PDF data is empty');
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      usePrinterSettings: true,
    );
  }

  // Show a print preview dialog with navigation controls
  static Future<void> showPrintPreview(
    BuildContext context,
    Uint8List pdfBytes, {
    String title = 'Dynamic Product Labels',
  }) async {
    if (pdfBytes.isEmpty) {
      throw Exception('PDF data is empty');
    }

    await PrintPreviewHelper.showPreview(
      context: context,
      pdfBytes: pdfBytes,
      title: title,
    );
  }

  /// Show system print dialog (legacy method for compatibility)
  static Future<void> showSystemPrintDialog(
    BuildContext context,
    Uint8List pdfBytes, {
    String title = 'Dynamic Product Labels',
  }) async {
    if (pdfBytes.isEmpty) {
      throw Exception('PDF data is empty');
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: title,
      usePrinterSettings: true,
    );
  }
}
