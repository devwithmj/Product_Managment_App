import 'dart:typed_data';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

import '../models/product.dart';
import '../models/label_template.dart';
import '../utils/label_layout.dart';

class PrintService {
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
      print('Fonts loaded successfully');
    } catch (e) {
      print('Error loading fonts: $e');
      // Fallback to default fonts
      _fontsLoaded = true;
    }
  }

  // Generate a PDF document for printing
  static Future<Uint8List> generatePdf({
    required List<Product> products,
    required LabelSize labelSize,
  }) async {
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
      LabelSize.letterWidthPoints,
      LabelSize.letterHeightPoints,
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

    // Determine if we're using the 3-column layout
    final bool isThreeColumn = labelSize.columnsPerPage == 4;

    // Organize products into pages
    final List<List<Product>> pages = LabelLayout.organizeProductsIntoPages(
      products,
      labelSize,
    );

    // Debug information
    print("PDF page size: ${pageFormat.width}pt × ${pageFormat.height}pt");
    print(
      "Labels per page: ${labelSize.rowsPerPage * labelSize.columnsPerPage}",
    );
    print("Total pages: ${pages.length}");
    print("Label dimensions: ${labelSize.widthCm}cm × ${labelSize.heightCm}cm");
    print(
      "Font sizes - Persian: ${labelSize.persianFontSize}, English: ${labelSize.englishFontSize}, Price: ${labelSize.priceFontSize}",
    );
    print("Using ${isThreeColumn ? '3-column' : 'standard'} layout");

    // For each page of products
    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final pageProducts = pages[pageIndex];

      // Skip empty pages
      if (pageProducts.isEmpty) continue;

      // Calculate positions for labels on this page using PDF points
      final positions = LabelLayout.calculateLabelPositionsForPDF(labelSize);

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
                print(
                  "Label $i position: left=${position.left}pt, top=${position.top}pt, width=${position.width}pt, height=${position.height}pt",
                );

                // Different label layouts based on the column count
                if (isThreeColumn) {
                  return _buildThreeColumnLabel(product, position, labelSize);
                } else {
                  return _buildStandardLabel(product, position, labelSize);
                }
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

  // Standard 2-column label layout
  static pw.Widget _buildStandardLabel(
    Product product,
    Rect position,
    LabelSize labelSize,
  ) {
    // Calculate proper font scaling based on template
    final persianFontSize = labelSize.persianFontSize * 0.8; // Adjust for PDF
    final englishFontSize = labelSize.englishFontSize * 0.8; // Adjust for PDF
    final priceFontSize = labelSize.priceFontSize * 0.7; // Adjust for PDF
    final centsFontSize =
        priceFontSize * 0.6; // Cents are 60% of main price size

    return pw.Positioned(
      left: position.left,
      top: position.top,
      child: pw.Container(
        width: position.width,
        height: position.height,
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        padding: const pw.EdgeInsets.all(4), // Added small padding
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            // Persian product name in RTL
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                product.fullNameFa,
                style: pw.TextStyle(
                  font: _vazirFontBold,
                  fontSize: persianFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            // Full product info in English
            pw.Text(
              product.fullNameEn,
              style: pw.TextStyle(fontSize: englishFontSize),
              textAlign: pw.TextAlign.center,
            ),

            // Price with correct formatting
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Dollar sign and main price
                pw.Text(
                  "\$${product.price.floor()}.",
                  style: pw.TextStyle(
                    fontSize: priceFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                // Cents
                pw.Text(
                  _getCentsFormatted(product.price),
                  style: pw.TextStyle(
                    fontSize: centsFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.Padding(
                  padding: pw.EdgeInsets.only(top: centsFontSize * 0.4),
                  child: pw.Text(
                    "/Ea.",
                    style: pw.TextStyle(fontSize: englishFontSize),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Compact 3-column label layout
  static pw.Widget _buildThreeColumnLabel(
    Product product,
    Rect position,
    LabelSize labelSize,
  ) {
    // Use smaller fonts for the 3-column layout
    final persianFontSize = labelSize.persianFontSize * 0.7; // Further reduced
    final englishFontSize = labelSize.englishFontSize * 0.7; // Further reduced
    final priceFontSize = labelSize.priceFontSize * 0.6; // Further reduced

    // For 3-column layout, shorten the product name to fit better
    String shortenedNameFa = product.nameFa;
    String shortenedNameEn = product.nameEn;

    return pw.Positioned(
      left: position.left,
      top: position.top,
      child: pw.Container(
        width: position.width,
        height: position.height,
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        padding: const pw.EdgeInsets.all(2), // Smaller padding for 3-column
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            // Persian product name (more compact)
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                shortenedNameFa,
                style: pw.TextStyle(
                  font: _vazirFontBold,
                  fontSize: persianFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            // English product name (more compact)
            pw.Text(
              shortenedNameEn,
              style: pw.TextStyle(fontSize: englishFontSize),
              textAlign: pw.TextAlign.center,
            ),

            // Price (simplified format for compact display)
            pw.Text(
              "\$${product.price.toStringAsFixed(2)}",
              style: pw.TextStyle(
                fontSize: priceFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Save PDF to temporary file (for debugging)
  static Future<void> _savePdfToFile(pw.Document pdf) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/debug_labels.pdf');
      await file.writeAsBytes(await pdf.save());
      print('Debug PDF saved to: ${file.path}');
    } catch (e) {
      print('Could not save debug PDF: $e');
    }
  }

  // Helper to get cents with correct formatting
  static String _getCentsFormatted(double price) {
    int cents = ((price - price.floor()) * 100).round();
    return cents.toString().padLeft(2, '0');
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

  // Show a print preview dialog
  static Future<void> showPrintPreview(
    BuildContext context,
    Uint8List pdfBytes,
  ) async {
    if (pdfBytes.isEmpty) {
      throw Exception('PDF data is empty');
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Product Labels',
      usePrinterSettings: true,
    );
  }
}
